require 'net/https'

# handler to push XML to Booking.com because new room type mapping was created
class BookingcomInventoryNewRoomHandler < InventoryNewRoomHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.inventory.property

    # property room type that has mapping to this channel
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel)
    end

    return if room_type_ids.blank?

    logs_by_room_type = change_set.logs_organized_by_room_type_id

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.request {
        xml.username BookingcomChannel::USERNAME
        xml.password BookingcomChannel::PASSWORD
        xml.hotel_id property.bookingcom_hotel_id

        logs_by_room_type.keys.each do |rt_id|
          next unless room_type_ids.include?(rt_id)

          room_type = property.room_types.find(rt_id)
          channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)
          room_type_logs = logs_by_room_type[rt_id]

          create_hotel_inventory_xml(xml, room_type_logs, channel_room_type_map)
        end
      }
    end

    request_xml = builder.to_xml
    puts request_xml
    BookingcomChannel.post_xml_change_set_channel(request_xml, change_set_channel, BookingcomChannel::AVAILABILITY)

  end

  def create_job(change_set)
   # all room types id in this change set
   # room_type_ids = change_set.room_type_ids

   cs = InventoryChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
   cs.delay.run
   
  end

  def channel
    BookingcomChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  def create_hotel_inventory_xml(xml, room_type_logs, channel_room_type_map)
    xml.room(:id => channel_room_type_map.bookingcom_room_type_id) {
      room_type_logs.each do |log|
        xml.date(:value => date_to_key(log.inventory.date)) {
          xml.rate(:id => channel_room_type_map.bookingcom_rate_plan_id)
          xml.roomstosell log.total_rooms
        }
      end
    }
  end

end
