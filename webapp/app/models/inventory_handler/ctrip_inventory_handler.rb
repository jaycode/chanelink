require 'net/https'

# class to handle booking.com push XML for inventory change
class CtripInventoryHandler < InventoryHandler

  def run(change_set_channel)
    change_set        = change_set_channel.change_set

    # get the property of this change set
    property          = change_set.logs.first.inventory.property
    property_channel  = property.channels.find_by_channel_id(channel.id)

    # property room type that has mapping to this channel
    room_type_ids     = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel)
    end

    return if room_type_ids.blank?

    prepare_availabilities_update_xml(room_type_ids, change_set, property) do |availabilities_sent, builder|
      if availabilities_sent
        request_xml   = builder.to_xml
        response      = CtripChannel.post_xml_change_set_channel(request_xml, change_set_channel, APP_CONFIG[:ctrip_inventories_update_endpoint])
        response_xml  = response.gsub(/xmlns=\"([^\"]*)\"/, "")
        xml_doc       = Nokogiri::XML(response_xml)
        unique_id     = xml_doc.xpath("//UniqueID")
        
        return {:unique_id => unique_id.first.attr('ID'), :type => unique_id.first.attr('Type')}
      else
        logs_inventory_get_failure CtripChannel.first.name, property, property_channel, APP_CONFIG[:ctrip_inventories_update_endpoint]
      end
    end

  end

  def prepare_availabilities_update_xml(room_type_ids, change_set, property, &block)
    availabilities_sent = false

    logs_by_room_type = change_set.logs_organized_by_room_type_id

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Envelope("xmlns:xsi" => CtripChannel::XMLNS_XSI, "xmlns:xsd" => CtripChannel::XMLNS_XSD) {
        xml.parent.namespace = xml.parent.add_namespace_definition("SOAP-ENV", CtripChannel::SOAP_ENV)
        xml['SOAP-ENV'].Header
        xml['SOAP-ENV'].Body {
          xml.OTA_HotelAvailNotifRQ(:Version => CtripChannel::API_VERSION, :PrimaryLangID => CtripChannel::PRIMARY_LANG, :xmlns => CtripChannel::XMLNS) {
            CtripChannel.construct_authentication_element(xml, property)
            xml.AvailStatusMessages(:HotelCode => property.settings(:ctrip_hotel_id)) {

              logs_by_room_type.keys.each do |rt_id|
                next unless room_type_ids.include?(rt_id)

                room_type = property.room_types.find(rt_id)
                channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)
                room_type_logs = logs_by_room_type[rt_id]

                create_hotel_inventory_xml(xml, room_type_logs, channel_room_type_map)

                availabilities_sent = true;

                # if this room type is availability linked by other room, then do push for the other room as well
                if room_type.is_inventory_feeder?
                  room_type.consumer_room_types.each do |consumer_room_type|
                    channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(consumer_room_type.id, channel.id)

                    if !channel_room_type_map.blank? and room_type_ids.include?(consumer_room_type.id)
                      create_hotel_inventory_xml(xml, room_type_logs, channel_room_type_map)
                    end
                  end
                end
              end

            }
          }
        }
      }
    end

    block.call(availabilities_sent, builder)
  end

  def channel
    CtripChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  def get_inventories(property, room_type, date_start, date_end, rate_type = nil)
    inventories = Array.new
    get_inventories_xml(property, room_type, date_start, date_end, rate_type) do |xml_doc|
      xml_doc.xpath('//RatePlan').each do |rate_plan_xml|
        rate_plan_xml.xpath('Rates/Rate').each do |rate_xml|
          inventories << InventoryXml.new(
            :room_type_id => rate_plan_xml.attr('RatePlanCode'),
            :rate_type_id => rate_plan_xml.attr('RatePlanCategory'),
            :date => rate_xml.attr('Start'),
            :total_rooms => rate_xml.attr('NumberOfUnits').to_i
          )
        end
      end
    end
    inventories
  end

  def get_inventories_xml(property, room_type, date_start, date_end, rate_type = nil, &block)
    channel = CtripChannel.first

    # Need to get ota room type and rate type:
    if rate_type.nil?
      room_type_channel_mapping = RoomTypeChannelMapping.first(
        :conditions => {
          :room_type_id => room_type.id,
          :channel_id => channel.id
        }
      )
    else
      room_type_channel_mapping = RoomTypeChannelMapping.first(
        :conditions => {
          :room_type_id => room_type.id,
          :rate_type_id => rate_type.id,
          :channel_id => channel.id
        }
      )
    end

    if room_type_channel_mapping.nil?
      raise I18n.t('activemodel.errors.models.inventory_handler.room_type_mapping_not_found')
    else
      CtripChannel.first.room_type_fetcher.retrieve_xml(property, date_start, date_end, room_type_channel_mapping.ota_room_type_id) do |xml_doc|
        block.call(xml_doc)
      end
    end
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
