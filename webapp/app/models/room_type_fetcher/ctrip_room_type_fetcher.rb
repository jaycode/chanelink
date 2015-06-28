require 'net/https'
# In Ctrip, this is RatePlan.
class CtripRoomTypeFetcher < RoomTypeFetcher
  include ChannelsHelper

  def retrieve(property, exclude_mapped_room = false, start_date = '', end_date = '')
    room_types = Array.new
    retrieve_xml(property, start_date, end_date) do |xml_doc|
      ctrip_room_types        = xml_doc.xpath('//RatePlan')
      ctrip_room_types.each do |rt|

        temp_rates            = Array.new
        ctrip_room_type_rates = rt.xpath('Rates/Rate')

        if ctrip_room_type_rates.count > 0
          ctrip_room_type_rates.each do |rate|

            temp_base_by_guest_amts = Array.new
            base_by_guest_amts      = rate.xpath('BaseByGuestAmts/BaseByGuestAmt')

            if base_by_guest_amts.count > 0
              base_by_guest_amts.each do |base_by_guest_amt|
                temp_base_by_guest_amts << CtripRoomTypeXmlRateAmt.new(base_by_guest_amt['AmountAfterTax'], base_by_guest_amt['CurrencyCode'], base_by_guest_amt['Code'])
              end
            end #end base_by_guest_amts.count

            temp_rates << CtripRoomTypeXmlRate.new(rate['Start'], rate['End'], rate['NumberOfUnits'], rate['Status'], temp_base_by_guest_amts)
          end
        end #end ctrip_room_type_rates.count

        rt_model = CtripRoomTypeXml.new(rt['RatePlanCode'], rt.xpath('./Description').first['Name'], rt['RatePlanCategory'], temp_rates)
        if exclude_mapped_room
          room_types << rt_model if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(
            :ota_room_type_id => rt_model.id, :channel_id => CtripChannel.first.id).blank?
        else
          room_types << rt_model
        end
      end #end each ctrip_room_types
    end

    room_types
  end

  # Retrieve but in xml format
  # This can be used to retrieve inventories as well since it returns available rooms.
  def retrieve_xml(property, start_date = '', end_date = '', ota_room_type_id = '', &block)
    if start_date.blank?
      start_date  = DateTime.now.to_date.strftime('%Y-%m-%d')
    end
    if end_date.blank?
      end_date    = DateTime.now.to_date.strftime('%Y-%m-%d')
    end

    property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, CtripChannel.first.id)

    # construct xml to request room type list
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Envelope("xmlns:xsi" => CtripChannel::XMLNS_XSI, "xmlns:xsd" => CtripChannel::XMLNS_XSD) {
        xml.parent.namespace = xml.parent.add_namespace_definition("SOAP-ENV", CtripChannel::SOAP_ENV)
        xml['SOAP-ENV'].Header
        xml['SOAP-ENV'].Body {
          xml.OTA_HotelRatePlanRQ(:Version => CtripChannel::API_VERSION,
                                  :PrimaryLangID => CtripChannel::PRIMARY_LANG,
                                  :xmlns => CtripChannel::XMLNS) {
            CtripChannel.construct_authentication_element(xml, property)
            xml.RatePlans {
              xml.RatePlan {
                xml.DateRange(:End => end_date, :Start => start_date)
                xml.RatePlanCandidates {
                  if ota_room_type_id.blank?
                    xml.RatePlanCandidate(:AvailRatesOnlyInd => 'false') {
                      xml.HotelRefs {
                        xml.HotelRef(:HotelCode => property.settings(:ctrip_hotel_id))
                      }
                    }
                  else
                    xml.RatePlanCandidate(:AvailRatesOnlyInd => 'false', :RatePlanCode => ota_room_type_id) {
                      xml.HotelRefs {
                        xml.HotelRef(:HotelCode => property.settings(:ctrip_hotel_id))
                      }
                    }
                  end
                }
              }
            }
          }
        }
      }
    end

    request_xml   = builder.to_xml
    response_xml  = CtripChannel.post_xml(request_xml, APP_CONFIG[:ctrip_rates_get_endpoint])
    response_xml  = response_xml.gsub(/xmlns=\"([^\"]*)\"/, "")

    # puts '============'
    # puts YAML::dump(request_xml)
    # puts '============'

    xml_doc = Nokogiri::XML(response_xml)
    success = xml_doc.xpath("//Success")

    if success.count > 0
      block.call xml_doc
    else
      logs_fetching_failure CtripChannel.first.name, request_xml, xml_doc, property, property_channel, APP_CONFIG[:ctrip_rates_get_endpoint]
    end
  end

end