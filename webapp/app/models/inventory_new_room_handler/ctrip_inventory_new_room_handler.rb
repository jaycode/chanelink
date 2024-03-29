require 'net/https'

# class to handle booking.com push XML for inventory change
class CtripInventoryNewRoomHandler < InventoryHandler

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

    logs_by_room_type = change_set.logs_organized_by_room_type_id

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Envelope("xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema") {
        xml.parent.namespace = xml.parent.add_namespace_definition("SOAP-ENV", "http://schemas.xmlsoap.org/soap/envelope/")
        xml['SOAP-ENV'].Header
        xml['SOAP-ENV'].Body {
          xml.OTA_HotelAvailNotifRQ(:Version => CtripChannel::API_VERSION, :PrimaryLangID => CtripChannel::PRIMARY_LANG, :xmlns => CtripChannel::XMLNS) {
            CtripChannel.construct_authentication_element(xml)
            xml.AvailStatusMessages(:HotelCode => property_channel.ctrip_hotel_code) {

              logs_by_room_type.keys.each do |rt_id|
                next unless room_type_ids.include?(rt_id)

                room_type = property.room_types.find(rt_id)
                channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)
                room_type_logs = logs_by_room_type[rt_id]

                create_hotel_inventory_xml(xml, room_type_logs, channel_room_type_map)
              end

            }
          }
        }
      }
    end

    request_xml = builder.to_xml
    CtripChannel.post_xml_change_set_channel(request_xml, change_set_channel, CtripChannel::AVAIL_NOTIF)

  end

  def channel
    CtripChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  # helper to build xml
  def create_hotel_inventory_xml(xml, room_type_logs, channel_room_type_map)
    room_type_logs.each do |log|
      xml.AvailStatusMessage(:BookingLimit => log.total_rooms, :BookingLimitMessageType => "SetLimit") {
        xml.StatusApplicationControl(:RatePlanCategory => channel_room_type_map.ota_rate_type_id,
                                     :RatePlanCode => channel_room_type_map.ota_room_type_id, :Start => date_to_key(log.inventory.date), :End => date_to_key(log.inventory.date)) {
          xml.RestrictionStatus(:Status => "Open")
        }
      }
    end
  end

end
