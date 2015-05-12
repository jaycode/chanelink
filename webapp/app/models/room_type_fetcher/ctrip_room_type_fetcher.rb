require 'net/https'

# class to retrieve ctrip room types
class CtripRoomTypeFetcher < RoomTypeFetcher

  def retrieve(property, exclude_mapped_room = false, start_date = '', end_date = '')
    room_types = Array.new
    retrieve_xml(property, exclude_mapped_room = false, start_date = '', end_date = '') do |xml_doc|
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
          room_types << rt_model if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:ctrip_room_rate_plan_code => rt_model.id, :channel_id => CtripChannel.first.id).blank?
        else
          room_types << rt_model
        end
      end #end each ctrip_room_types
    end

    room_types
  end

  def retrieve_by_rate_plan_code(property, rate_plan_code, date_start, date_end)
    room_types = Array.new
    retrieve_xml_by_rate_plan_code(property, rate_plan_code, date_start, date_end) do |xml_doc|
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

        room_types << rt_model
      end #end each ctrip_room_types
    end

    room_types
  end

  # Retrieve but in xml format
  def retrieve_xml(property, exclude_mapped_room = false, start_date = '', end_date = '', &block)
    if start_date.empty?
      start_date  = DateTime.now.to_date.strftime('%Y-%m-%d')
    end
    if end_date.empty?
      end_date    = DateTime.now.to_date.strftime('%Y-%m-%d')
    end

    property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, CtripChannel.first.id)
    room_types        = Array.new

    # construct xml to request room type list
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Envelope("xmlns:xsi" => CtripChannel::XMLNS_XSI, "xmlns:xsd" => CtripChannel::XMLNS_XSD) {
        xml.parent.namespace = xml.parent.add_namespace_definition("SOAP-ENV", CtripChannel::SOAP_ENV)
        xml['SOAP-ENV'].Header
        xml['SOAP-ENV'].Body {
          xml.OTA_HotelRatePlanRQ(:Version => CtripChannel::API_VERSION, :PrimaryLangID => CtripChannel::PRIMARY_LANG, :xmlns => CtripChannel::XMLNS) {
            CtripChannel.construct_authentication_element(xml, property)
            xml.RatePlans {
              xml.RatePlan {
                xml.DateRange(:End => end_date, :Start => start_date)
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
  end

  # Retrieve but in xml format
  def retrieve_xml_by_rate_plan_code(property, rate_plan_code, date_start, date_end, &block)

    property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, CtripChannel.first.id)
    room_types        = Array.new

    # construct xml to request room type list
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Envelope("xmlns:xsi" => CtripChannel::XMLNS_XSI, "xmlns:xsd" => CtripChannel::XMLNS_XSD) {
        xml.parent.namespace = xml.parent.add_namespace_definition("SOAP-ENV", CtripChannel::SOAP_ENV)
        xml['SOAP-ENV'].Header
        xml['SOAP-ENV'].Body {
          xml.OTA_HotelRatePlanRQ(:Version => CtripChannel::API_VERSION, :PrimaryLangID => CtripChannel::PRIMARY_LANG, :xmlns => CtripChannel::XMLNS) {
            CtripChannel.construct_authentication_element(xml, property)
            xml.RatePlans {
              xml.RatePlan {
                xml.DateRange(:End => date_end, :Start => date_start)
                xml.RatePlanCandidates {
                  xml.RatePlanCandidate(:AvailRatesOnlyInd => 'false', :RatePlanCode => rate_plan_code) {
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

    request_xml   = builder.to_xml
    response_xml  = CtripChannel.post_xml(request_xml, APP_CONFIG[:ctrip_rates_get_endpoint])
    response_xml  = response_xml.gsub(/xmlns=\"([^\"]*)\"/, "")

    puts '============'
    puts YAML::dump(response_xml)
    puts '============'

    xml_doc = Nokogiri::XML(response_xml)
    success = xml_doc.xpath("//Success")

    if success.count > 0
      block.call xml_doc
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
  end

end
