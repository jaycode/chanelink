# object to hold expedia booking
class ExpediaBooking < Booking

  TYPE_NEW = 'Book'
  TYPE_MODIFY = 'Modify'
  TYPE_CANCEL = 'Cancel'

  validates :expedia_booking_id, :presence => true, :uniqueness => true

  before_create :generate_confirm_numbers

  before_save :set_booking_status

  after_create :convert_to_inventory_log

  after_save :send_confirmation

  # random generate confirm numbers to to do confirmation with expedia
  def generate_confirm_numbers
    self.expedia_confirm_number = Digest::MD5.hexdigest(rand(Time.now.to_i).to_s)
  end

  def set_booking_status
    self.booking_status = BookingStatus.new_type if self.type_new?
    self.booking_status = BookingStatus.modify_type if self.type_modify?
    self.booking_status = BookingStatus.cancel_type if self.type_cancel?
  end

  def type_new?
    self.status == TYPE_NEW
  end

  def type_modify?
    self.status == TYPE_MODIFY
  end

  def type_cancel?
    self.status == TYPE_CANCEL
  end

  # send new booking data to customer
  def send_notification
    email = channel.get_email_for_booking_notification(self)
    Notifier.delay.email_expedia_booking_notification(email, self)
  end

  # confirm to expedia that we already received the booking
  def send_confirmation
    return if self.expedia_confirmed?
    send_notification

    property = self.property
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.BookingConfirmRQ('xmlns' => ExpediaChannel::XMLNS_BC) {
        xml.Authentication(:username => property.expedia_username, :password => property.expedia_password)
        
        xml.Hotel(:id => property.expedia_hotel_id)
        
        xml.BookingConfirmNumbers {
          xml.BookingConfirmNumber(:bookingID => self.expedia_booking_id, :bookingType => self.status, :confirmNumber => self.expedia_confirm_number, :confirmTime => DateTime.now.strftime("%Y-%m-%d\T%H:%M:%S%:z"))
        }
      }
    end

    request_xml = builder.to_xml
    response_xml = ExpediaChannel.post_xml(request_xml, ExpediaChannel::BC)

    puts request_xml
    puts response_xml

    xml_doc  = Nokogiri::XML(response_xml)
    xml_doc.remove_namespaces!
    success = xml_doc.xpath("//Success")

    if !success.blank?
      self.update_attribute(:expedia_confirmed, true)
    end
  end

  def convert_to_inventory_log
    return if self.type_new?

    pc = PropertyChannel.find_by_property_id_and_channel_id(self.property.id, self.channel.id)
    
    if self.room_type.blank?
      # we dont have the room type for this booking? ignore
    elsif pc.blank?
      # check if agoda belong to a pool
      # if channel does not belong to a pool for this property, just ignore
    else
      pool = pc.pool
      date_start = self.date_start
      date_end = self.date_end
      logs = Array.new
      while date_start < date_end
        inv = Inventory.find_by_date_and_room_type_id_and_pool_id(date_start, self.room_type.id, pool.id)

        if date_start >= DateTime.now.beginning_of_day
          if inv.blank?
            # rooms not enough, send warning
            puts 'inventory is blank'
            inventory = Inventory.new
            inventory.date = date_start
            inventory.total_rooms = 0
            inventory.room_type_id = self.room_type.id
            inventory.property = pc.property
            inventory.pool_id = pool.id

            inventory.save
            logs << create_inventory_log(inventory)

            ZeroInventoryAlert.create_for_property(inventory, self.property)

          elsif inv.total_rooms >= self.total_rooms
            inv.total_rooms = inv.total_rooms - self.total_rooms
            inv.save
            logs << create_inventory_log(inv)
          else
            inv.total_rooms = 0
            inv.save
            logs << create_inventory_log(inv)

            ZeroInventoryAlert.create_for_property(inv, self.property)
          end
        end
        date_start = date_start + 1.day
      end
      InventoryChangeSet.create_job_for_booking(logs, pool, self.channel)
    end
  end

  def create_inventory_log(inventory)
    BookingInventoryLog.create(:inventory_id => inventory.id, :total_rooms => inventory.total_rooms, :booking_id => self.id)
  end

  def channel
    ExpediaChannel.first
  end
  
end

