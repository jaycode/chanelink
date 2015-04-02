require 'net/https'

# handler to push XML to Agoda because new room type mapping was created
class AgodaInventoryNewRoomHandler < InventoryNewRoomHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.inventory.property
    property_channel = property.channels.find_by_channel_id(channel.id)

    # property room type that has mapping to this channel
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel)
    end

    return if room_type_ids.blank?

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.SetHotelInventoryRequest('xmlns' => AgodaChannel::XMLNS) {
        xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
        xml.HotelInventoryList {
          change_set.logs.each do |log|
            inv = log.inventory
            room_type = inv.room_type
            channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)

            if !channel_room_type_map.blank? and room_type_ids.include?(room_type.id)
              create_hotel_inventory_xml(xml, channel_room_type_map.agoda_room_type_id, inv.date, log.total_rooms, channel_room_type_map, property_channel)
            end
            
          end
        }
      }
    end

    request_xml = builder.to_xml
    AgodaChannel.post_xml_change_set_channel(request_xml, change_set_channel)
  end

  def create_job(change_set)
   # all room types id in this change set
   # room_type_ids = change_set.room_type_ids
   cs = InventoryChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
   cs.delay.run
   
  end

  def channel
    AgodaChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  def create_hotel_inventory_xml(xml, channel_room_type_id, date, rooms, rtcm, property_channel)
    xml.HotelInventory {
      xml.RoomType(:RoomTypeID => channel_room_type_id, :RatePlanID => AgodaChannel::DEFAULT_RATE_PLAN_ID)
      xml.DateRange(:Type => "Stay", :Start => date_to_key(date), :End => date_to_key(date))
      unless rtcm.agoda_extra_bed_rate.blank?
        xml.InventoryRate(:Currency => AgodaChannel.get_currency(property_channel)) {
          xml.ExtraBed AgodaChannel.get_extra_bed(rtcm)
        }
      end
      xml.InventoryAllotment {
        xml.RegularAllotment rooms
        xml.BreakfastIncluded rtcm.agoda_breakfast_inclusion
      }
    }
  end

end
