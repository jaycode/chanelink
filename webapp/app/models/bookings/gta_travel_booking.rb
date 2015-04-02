# object to hold bookingcom booking data
class GtaTravelBooking < Booking

  TYPE_CONFIRMED = 'Confirmed'

  validates :gta_travel_booking_id, :presence => true, :uniqueness => true

  before_save :set_booking_status
  after_create :convert_to_inventory_log

  def set_booking_status
    self.booking_status = BookingStatus.new_type if self.type_confirmed?
  end

  def type_confirmed?
    self.status == TYPE_CONFIRMED
  end

  def convert_to_inventory_log
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
    GtaTravelChannel.first
  end

end

