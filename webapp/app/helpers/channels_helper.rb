module ChannelsHelper
  def logs_rate_update_failure(channel_name, request_xml, xml_doc, property, property_channel, endpoint)
    logs_failure('Updating rates failed', channel_name, request_xml, xml_doc, property, property_channel, endpoint)
  end

  def logs_inventory_get_failure(channel_name, request_xml, xml_doc, property, property_channel, endpoint)
    logs_failure('Fetching inventories failed', channel_name, request_xml, xml_doc, property, property_channel, endpoint)
  end

  def logs_fetching_failure(channel_name, request_xml, xml_doc, property, property_channel, endpoint)
    logs_failure('Fetching room types failed', channel_name, request_xml, xml_doc, property, property_channel, endpoint)
  end

  def logs_get_bookings_failure(channel_name, request_xml, xml_doc, property, property_channel, endpoint)
    logs_failure('Get bookings failed', channel_name, request_xml, xml_doc, property, property_channel, endpoint)
  end

  def logs_failure(message, channel_name, request_xml, xml_doc, property, property_channel, endpoint)
    api_logger = Logger.new("#{Rails.root}/log/api_errors.log")
    api_logger.error("[#{Time.now}] #{message}.\n
PropertyChannel ID: #{property_channel.id}
Channel: #{channel_name}
Property: #{property.id} - #{property.name}
SOAP XML sent to #{endpoint}\n
xml sent:\n#{request_xml}\n
xml retrieved:\n#{xml_doc.to_xhtml(indent: 3)}")

    raise Exception,
          I18n.t(
            'activemodel.errors.models.room_type_fetcher.fetch_failed',
            {:channel => channel_name,
             :contact_us_link => ActionController::Base.helpers.link_to(
               I18n.t('activemodel.errors.models.room_type_fetcher.contact_us'),
               "mailto:#{APP_CONFIG[:support_email]}?Subject=#{I18n.t(
                 'activemodel.errors.models.room_type_fetcher.email_subject',
                 :property_id => property.id)}",
               {
                 :target => '_blank'
               })
            })
  end
end
