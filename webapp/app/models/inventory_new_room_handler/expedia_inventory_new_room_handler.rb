require 'net/https'

# handler to push XML to Expedia because new room type mapping was created
class ExpediaInventoryNewRoomHandler < InventoryNewRoomHandler

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

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.AvailRateUpdateRQ('xmlns' => ExpediaChannel::XMLNS_AR) {
      xml.Authentication(:username => property.expedia_username, :password => property.expedia_password)
      xml.Hotel(:id => property.expedia_hotel_id)
        change_set.logs.each do |log|
          inv = log.inventory
            room_type = inv.room_type
            channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)

            if !channel_room_type_map.blank? and room_type_ids.include?(room_type.id)
              create_hotel_inventory_xml(xml, channel_room_type_map.expedia_room_type_id, inv.date, log.total_rooms)
            end
        end
      }
    end

    request_xml = builder.to_xml
    ExpediaChannel.post_xml_change_set_channel(request_xml, change_set_channel, ExpediaChannel::AR)

  end

  def create_job(change_set)
   # all room types id in this change set
   # room_type_ids = change_set.room_type_ids

   cs = InventoryChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
   cs.delay.run
   
  end

  def channel
    ExpediaChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  def create_hotel_inventory_xml(xml, channel_room_type_id, date, rooms)
    xml.AvailRateUpdate {
      xml.DateRange(:from => date_to_key(date), :to => date_to_key(date))
      xml.RoomType(:id => channel_room_type_id) {
        xml.Inventory(:totalInventoryAvailable => rooms)
      }
    }
  end

end
