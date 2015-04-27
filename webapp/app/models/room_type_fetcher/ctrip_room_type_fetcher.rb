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
    success = xml_doc.xpath("/soap:Envelope/soap:Body/OTA_HotelRatePlanRS/Success")
    if success
      # @logger = Logger.new("#{Rails.root}/log/custom.log")
      # @logger.error("resulting xml: #{xml_doc.to_xhtml(indent: 3)}")
      ctrip_room_types = xml_doc.xpath('//RatePlan')
      ctrip_room_types.each do |rt|
        rt_model = CtripRoomTypeXml.new(rt["RatePlanCode"], rt.xpath("./Description").first["Name"], rt["RatePlanCategory"])
        if exclude_mapped_room
          room_types << rt_model if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:ctrip_room_rate_plan_code => rt_model.id, :channel_id => CtripChannel.first.id).blank?
        else
          room_types << rt_model
        end
      end
    end
    room_types
  end

end
