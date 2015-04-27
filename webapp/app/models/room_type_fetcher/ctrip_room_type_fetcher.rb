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
    xml_doc  = Nokogiri::XML(response_xml)
    success = xml_doc.xpath("/soap:Envelope/soap:Body/OTA_HotelRatePlanRS/Success")
    puts "xxx"
    if success
      # ctrip_room_types = xml_doc.xpath("/soap:Envelope/soap:Body/OTA_HotelRatePlanRS/RatePlans/RatePlan")
      # puts response_xml
      puts "resulting xml: #{xml_doc.to_xhtml(indent: 3)}"
      puts "aaa"
      ctrip_room_types = xml_doc.xpath('//RatePlans/*')
      puts "after xpath: #{ctrip_room_types.inspect}"
      puts "count = #{ctrip_room_types.count}"
      ctrip_room_types.each do |rt|
        puts rt.inspect
        rt = CtripRoomTypeXml.new(rt["RatePlanCode"], rt.xpath("./ctrip:Description", "ctrip" => CtripChannel::XMLNS).first["Name"], rt["RatePlanCategory"])
        if exclude_mapped_room
          room_types << rt if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:ctrip_room_rate_plan_code => rt.id, :channel_id => CtripChannel.first.id).blank?
        else
          room_types << rt
        end
      end
    end
    room_types
  end

end
