require 'net/https'

# class to handle booking.com push XML for inventory change
class CtripInventoryHandler < InventoryHandler

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

    prepare_availabilities_update_xml(room_type_ids, change_set, property) do |availabilities_sent, builder|
      if availabilities_sent
        request_xml = builder.to_xml
        response = CtripChannel.post_xml_change_set_channel(request_xml, change_set_channel, APP_CONFIG[:ctrip_rates_update_endpoint])
      else
        # Todo: logs the error here
        pi_logger = Logger.new("#{Rails.root}/log/api_errors.log")
        api_logger.error("[#{Time.now}] Update availabilities failed.\n
PropertyChannel ID: #{property_channel.id}
Channel: #{CtripChannel.first.name}
Property: #{property.id} - #{property.name}
SOAP XML sent to #{APP_CONFIG[:ctrip_rates_get_endpoint]}\n
xml sent:\n#{request_xml}\n
xml retrieved:\n#{xml_doc.to_xhtml(indent: 3)}")

        raise Exception, I18n.t('activemodel.errors.models.room_type_fetcher.fetch_failed', {
          :channel => CtripChannel.name,
          :contact_us_link => ActionController::Base.helpers.link_to(I18n.t('activemodel.errors.models.room_type_fetcher.contact_us'),
            "mailto:#{APP_CONFIG[:support_email]}?Subject=#{I18n.t('activemodel.errors.models.room_type_fetcher.email_subject', :property_id => property.id)}",
            {
              :target => '_blank'
          })
        })
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

  def create_job(change_set, delay = true)
    # all room types id in this change set
    # room_type_ids = change_set.room_type_ids

    cs = InventoryChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
    if delay
      cs.delay.run
    else
      cs.run
    end
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
        xml.StatusApplicationControl(:RatePlanCategory => channel_room_type_map.settings(:ctrip_room_rate_plan_category), :RatePlanCode => channel_room_type_map.settings(:ctrip_room_rate_plan_code), :Start => date_to_key(log.inventory.date), :End => date_to_key(log.inventory.date)) {
          xml.RestrictionStatus(:Status => "Open")
        }
      }
    end
  end

end
