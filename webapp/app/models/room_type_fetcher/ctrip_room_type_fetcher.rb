require 'net/https'

# class to retrieve ctrip room types
class CtripRoomTypeFetcher < RoomTypeFetcher

  def retrieve(property, exclude_mapped_room = false)

    property_channel = PropertyChannel.find_by_property_id_and_channel_id(property.id, CtripChannel.first.id)

    room_types = Array.new

    # construct xml to request room type list
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Envelope("xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema") {
        xml.parent.namespace = xml.parent.add_namespace_definition("SOAP-ENV", "http://schemas.xmlsoap.org/soap/envelope/")
        xml['SOAP-ENV'].Header
        xml['SOAP-ENV'].Body {
          xml.OTA_HotelRatePlanRQ(:Version => CtripChannel::API_VERSION, :PrimaryLangID => CtripChannel::PRIMARY_LANG, :xmlns => CtripChannel::XMLNS) {
            CtripChannel.construct_authentication_element(xml, property)
            xml.RatePlans {
              xml.RatePlan {
                xml.DateRange(:End => '2015-02-25', :Start => '2015-02-23')
                xml.RatePlanCandidates {
                  xml.RatePlanCandidate(:AvailRatesOnlyInd => 'false') {
                    xml.HotelRefs {
                      xml.HotelRef(:HotelCode => property.settings(:ctrip_hotel_id))
                    }
                  }
                }
              }
            }
          }
        }
      }
    end
    request_xml = builder.to_xml
    response_xml = CtripChannel.post_xml(request_xml, APP_CONFIG[:ctrip_rates_get_endpoint])
    response_xml = response_xml.gsub(/xmlns=\"([^\"]*)\"/, "")
    xml_doc  = Nokogiri::XML(response_xml)
    success = xml_doc.xpath("//Success")
    if success.count > 0
      ctrip_room_types = xml_doc.xpath('//RatePlan')
      ctrip_room_types.each do |rt|
        rt_model = CtripRoomTypeXml.new(rt["RatePlanCode"], rt.xpath("./Description").first["Name"], rt["RatePlanCategory"])
        if exclude_mapped_room
          room_types << rt_model if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:ctrip_room_rate_plan_code => rt_model.id, :channel_id => CtripChannel.first.id).blank?
        else
          room_types << rt_model
        end
      end
    else
      api_logger = Logger.new("#{Rails.root}/log/api_errors.log")
      api_logger.error("[#{Time.now}] Fetching room types failed.\n
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
    room_types
  end

end
