class Api::Soap::CtripController < ApplicationController
  include XmlHelper
  def index
    action = params[:Envelope][:Body].keys[0]
    @xml_doc = Nokogiri::XML(request.raw_post)
    if authenticate
      case action
        when "OTA_HotelResRQ"
          hotel_res_rq
        when "OTA_CancelRQ"
          cancel_rq
        else
          render nil
      end
    end
  end
protected
  def authenticate
    true
  end
  def cancel_rq
    unique_id_nodes = @xml_doc.xpath('//ctrip:UniqueID', 'ctrip' => CtripChannel::XMLNS)
    success = false
    error_message = ''
    working_unique_id = ''
    unique_id_nodes.each do |unique_id_node|
      unique_id = unique_id_node.attr('ID')
      bookings = CtripBooking.all(:conditions => {:ota_booking_id => unique_id})
      if bookings.blank?
        error_message = t('api.error_booking_not_found')
      else
        bookings.each do |booking|
          working_unique_id = unique_id
          CtripChannel.first.booking_handler.cancel_booking(booking)
          success = true
        end
      end
    end
    if success
      render :xml => success_xml(working_unique_id, 'OTA_CancelRS')
    else
      render :xml => failed_xml(103, error_message, 'OTA_CancelRS')
    end
  end
  def hotel_res_rq
    unique_id = @xml_doc.xpath('//ctrip:UniqueID', 'ctrip' => CtripChannel::XMLNS).attr('ID').value
    success = false
    ota_hotel_id = @xml_doc.xpath('//ctrip:BasicPropertyInfo', 'ctrip' => CtripChannel::XMLNS).attr('HotelCode').value
    if ota_hotel_id.blank?
      # Throw exception: Hotel ID can't be blank
      failed_xml(100, t('api.error_id_empty'))
    else
      guest_name = @xml_doc.xpath('//ctrip:ContactPerson/ctrip:PersonName/ctrip:GivenName',
                                  'ctrip' => CtripChannel::XMLNS).text
      properties = Property.all(:conditions => ["settings LIKE ?", "%ctrip_hotel_id\": \"#{ota_hotel_id}\"%"])
      timespan = @xml_doc.xpath('//ctrip:TimeSpan', 'ctrip' => CtripChannel::XMLNS)
      date_start = timespan.attr('Start').value
      date_end = timespan.attr('End').value
      dates = []
      date_start.to_date.upto(date_end.to_date) do |date|
        dates << date
      end
      # The last day isn't counted.
      dates.pop

      amount = 0.0

      properties.each do |property|
        # This is the parameters we are going to send to InventoryChangeSet
        update_params = {}

        room_rates = @xml_doc.xpath('//ctrip:RoomRate', 'ctrip' => CtripChannel::XMLNS)

        # Getting pools
        pools = Pool.all(
          :conditions => ["`property_channels`.channel_id = ? AND `pools`.property_id = ?",
                          CtripChannel.first.id, property.id],
          :joins => :property_channels)

        # Todo: I know it's weird that pools are not used here, but this is legacy system so let's
        #       keep it for now.
        room_rates.each do |room_rate|
          number_of_units = room_rate.attr('NumberOfUnits').to_i
          # Getting room_types through room_type_channel_mappings
          ota_room_type_id = room_rate.attr('RatePlanCode')
          rtcms = RoomTypeChannelMapping.all(
            :conditions => ["`room_type_channel_mappings`.channel_id = ? AND
ota_room_type_id = ? AND `properties`.id = ?", CtripChannel.first.id, ota_room_type_id, property.id],
            :joins => {:room_type => :property})
          room_types = rtcms.collect &:room_type
          room_types.uniq!

          # In ctrip, amount given is per room on multiple date ranges.
          # Other OTAs may handle this differently.
          rates = @xml_doc.xpath('//ctrip:Rate',
                                 'ctrip' => CtripChannel::XMLNS)
          rates.each do |rate|
            rate_start_date = get_element_value(rate.attr('EffectiveDate')).to_date
            rate_end_date = get_element_value(rate.attr('ExpireDate')).to_date
            days = (rate_end_date - rate_start_date).to_i

            # If property does not allow exchange rates to be changed,
            # Todo: What to do here? I would suggest to create a default exchange rate table.
            # Otherwise property_channel should have rate multiplier.
            # Todo: But then again, rate multiplier in property_channel
            #       does not work with multiple rates.
            # For now, lets be very stupid and use existing methods.
            currency_code = rate.xpath('//ctrip:Base', 'ctrip' => CtripChannel::XMLNS).attr('CurrencyCode').value
            property_channel = PropertyChannel.where(
              :channel_id => CtripChannel.first.id,
              :property_id => property.id
            ).first
            unless property_channel.blank?
              currency_conversion = CurrencyConversion.first(
                :conditions => ["property_channel_id = ? AND `currencies`.code = ?",
                                property_channel.id,
                                currency_code],
                :joins => :to_currency
              )
            end

            room_rate = rate.xpath('//ctrip:Base', 'ctrip' => CtripChannel::XMLNS).attr('AmountAfterTax').value.to_f
            if !currency_conversion.blank?
              amount += currency_conversion.convert_to_base_currency(room_rate * number_of_units * days)
            else
              amount += room_rate * number_of_units * days
            end
          end
          # End of stupidity

          # Once we get room types, dates, and number of units we can start filling update_params.
          room_types.each do |room_type|
            if update_params[room_type.id.to_s].blank?
              update_params[room_type.id.to_s] = {}
              # Create bookings
              pools.each do |pool|
                another_booking = CtripBooking.first(
                  :conditions => {
                    :channel_id => CtripChannel.first.id,
                    :property_id => room_type.property_id,
                    :room_type_id => room_type.id,
                    :pool_id => pool.id,
                    :ota_booking_id => unique_id
                  }
                )
                if another_booking.blank?
                  CtripBooking.create(
                    :channel_id => CtripChannel.first.id,
                    :property_id => room_type.property_id,
                    :room_type_id => room_type.id,
                    :pool_id => pool.id,
                    :status => Booking::STATUS_BOOK,
                    :guest_name => guest_name,
                    :total_rooms => number_of_units,
                    :date_start => date_start.to_date,
                    :date_end => date_end.to_date,
                    :ota_booking_id => unique_id,
                    :booking_xml => @xml_doc.to_xml,
                    :booking_date => Date.today,
                    :amount => amount
                  )
                end
              end
            end
            dates.each do |date|
              update_params[room_type.id.to_s][date.to_s] = "-#{number_of_units}"
            end
          end
        end

        unless update_params.blank?
          pools.each do |pool|
            # This is similar to updating inventories from InventoriesController.
            change_set = InventoryChangeSet.update_inventories(property, pool.id, update_params)
            property_channels = PropertyChannel.find_all_by_pool_id(pool.id)

            # Go through each channel inventory handler and ask them to create push xml job
            # except for Ctrip channel.
            property_channels.each do |pc|
              channel = pc.channel
              if channel != CtripChannel.first
                channel.inventory_handler.create_job(change_set) unless pc.disabled?
              end
            end

            success = true
          end
        end
      end
    end

    if success
      render :xml => success_xml(unique_id)
    else
      render :xml => failed_xml(101, t('api.error_unknown'))
    end
  end

  def failed_xml(code, message, tag = 'OTA_HotelResRS')
    builder = Nokogiri::XML::Builder.new :encoding => 'utf-8' do |xml|
      xml['soap'].Envelope(
        'xmlns:soap' => CtripChannel::SOAP_ENV,
        'xmlns:xsi' => CtripChannel::XMLNS_XSI,
        'xmlns:xsd' => CtripChannel::XMLNS_XSD) {
        # xml.parent.namespace = xml.parent.add_namespace_definition('soap', CtripChannel::SOAP_ENV)
        xml['soap'].Body {
          xml.send(tag, {
            # Looks like having xsi and xsd again here is invalid but ctrip doc needs them...
            'xmlns:xsi' => CtripChannel::XMLNS_XSI,
            'xmlns:xsd' => CtripChannel::XMLNS_XSD,

            'xmlns' => CtripChannel::XMLNS,
            'EchoToken' => '',
            'Version' => '2.1'}) {
            xml.Failed
            xml.Message({:ID => code}, message)
          }
        }
      }
    end
    builder.to_xml
  end
  def success_xml(unique_id, tag = 'OTA_HotelResRS')
    # <?xml version="1.0" encoding="utf-8"?>
    # <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    # <soap:Body>
    # <OTA_HotelResRS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" EchoToken="" Version="2.1" xmlns="http://www.opentravel.org/OTA/2003/05">
    #   <Success />
    #   <HotelReservations>
    #     <HotelReservation ResStatus="S">
    #       <ResGlobalInfo>
    #         <HotelReservationIDs>
    #          <HotelReservationID ResID_Type="501" ResID_Value="900066320" />
    #           <HotelReservationID ResID_Type="502" ResID_Value="CTP-900066320" />
    #         </HotelReservationIDs>
    #       </ResGlobalInfo>
    #     </HotelReservation>
    #   </HotelReservations>
    # </OTA_HotelResRS>
    # </soap:Body>
    # </soap:Envelope>
    builder = Nokogiri::XML::Builder.new :encoding => 'utf-8' do |xml|
      xml['soap'].Envelope(
        'xmlns:soap' => CtripChannel::SOAP_ENV,
        'xmlns:xsi' => CtripChannel::XMLNS_XSI,
        'xmlns:xsd' => CtripChannel::XMLNS_XSD) {
        # xml.parent.namespace = xml.parent.add_namespace_definition('soap', CtripChannel::SOAP_ENV)
        xml['soap'].Body {
          xml.send(tag, {
            # Looks like having xsi and xsd again here is invalid but ctrip doc needs them...
            'xmlns:xsi' => CtripChannel::XMLNS_XSI,
            'xmlns:xsd' => CtripChannel::XMLNS_XSD,

            'xmlns' => CtripChannel::XMLNS,
            'EchoToken' => '',
            'Version' => '2.1'}) {
            xml.Success
            case tag
              when 'OTA_HotelResRS'
                xml.HotelReservations {
                  xml.HotelReservation(:ResStatus => 'S') {
                    xml.ResGlobalInfo {
                      xml.HotelReservationIDs {
                        xml.HotelReservationID(:ResID_Type => '501', :ResID_Value => unique_id)
                        xml.HotelReservationID(:ResID_Type => '502', :ResID_Value => "CTP-#{unique_id}")
                      }
                    }
                  }
                }
              when 'OTA_CancelRS'
                xml.UniqueID(:Type => '501', :ID => unique_id)
              else
                xml.UniqueID(:Type => '501', :ID => unique_id)
            end
          }
        }
      }
    end
    builder.to_xml
  end
end