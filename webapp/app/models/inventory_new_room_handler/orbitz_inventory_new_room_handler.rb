require 'net/https'

# class to handle orbitz push XML for inventory change
class OrbitzInventoryNewRoomHandler < InventoryNewRoomHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # need to control amount of data going to expedia, divide by 150 rows each
    logs = change_set.logs

    if logs.size > OrbitzChannel::SIZING
      logs_to_slice = Array.new(logs)
      index = 1
      while !logs_to_slice.blank?
        logs_fragment = logs_to_slice.slice!(0, OrbitzChannel::SIZING)
        run_by_logs(logs_fragment, change_set_channel, index)

        index = index + 1
      end
    else
      run_by_logs(logs, change_set_channel)
    end

  end

  def run_by_logs(logs_to_use, change_set_channel, fragment_id = nil)
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
      xml.OTA_HotelAvailNotifRQ(:xmlns => OrbitzChannel::XMLNS) {
        OrbitzChannel.construct_auth_element(xml)
        xml.AvailStatusMessages(:ChainCode => property_channel.orbitz_chain_code, :HotelCode => property_channel.orbitz_hotel_code) {
          logs_to_use.each do |log|
            inv = log.inventory
            room_type = inv.room_type
            channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)

            if !channel_room_type_map.blank? and room_type_ids.include?(room_type.id)
              create_hotel_inventory_xml(xml, channel_room_type_map.orbitz_room_type_id, inv.date, log.total_rooms, channel_room_type_map, property_channel)
            end
          end
        }
      }
    end

    request_xml = builder.to_xml
    OrbitzChannel.post_xml_change_set_channel(request_xml, change_set_channel, OrbitzChannel::OTHER)
  end

  def create_job(change_set)
   cs = InventoryChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
   cs.delay.run
  end

  def channel
    OrbitzChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  # helper to build XML push
  def create_hotel_inventory_xml(xml, channel_room_type_id, date, rooms, rtcm, property_channel)
    xml.AvailStatusMessage(:BookingLimit => rooms, :BookingLimitMessageType => "SetLimit") {
      xml.StatusApplicationControl(:Start => date_to_key(date), :End => date_to_key(date), :InvCode => channel_room_type_id, :InvCodeApplication => "InvCode", :RatePlanCode => rtcm.orbitz_rate_plan_id)
    }
  end

end
