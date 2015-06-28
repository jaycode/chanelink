class Api::Soap::CtripController < ApplicationController
  def index
    action = params[:Envelope][:Body].keys[0]
    @xml_doc = Nokogiri::XML(request.raw_post)
    @unique_id = @xml_doc.xpath('//ctrip:UniqueID', 'ctrip' => CtripChannel::XMLNS).attr('ID').value
    case action
      when "OTA_HotelResRQ"
        hotel_res_rq
      else
        render nil
    end
  end
protected
  def hotel_res_rq
    success = false
    ota_hotel_id = @xml_doc.xpath('//ctrip:BasicPropertyInfo', 'ctrip' => CtripChannel::XMLNS).attr('HotelCode').value
    if ota_hotel_id.blank?
      # Throw exception: Hotel ID can't be blank
    else
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

          # Once we get room types, dates, and number of units we can start filling update_params.
          room_types.each do |room_type|
            if update_params[room_type.id.to_s].blank?
              update_params[room_type.id.to_s] = {}
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

            # go through each channel inventory handler and ask them to create push xml job
            property_channels.each do |pc|
              channel = pc.channel
              channel.inventory_handler.create_job(change_set) unless pc.disabled?
            end

            success = true
          end
        end
      end
    end

    if success
      render :xml => success_xml
    else
      render :text => "Not Awesome"
    end
  end

  def success_xml
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
          xml.OTA_HotelResRS(
            # Looks like having xsi and xsd again here is invalid but ctrip doc needs them...
            'xmlns:xsi' => CtripChannel::XMLNS_XSI,
            'xmlns:xsd' => CtripChannel::XMLNS_XSD,

            'xmlns' => CtripChannel::XMLNS,
            'EchoToken' => '',
            'Version' => '2.1') {
            xml.Success
            xml.HotelReservations {
              xml.HotelReservation(:ResStatus => 'S') {
                xml.ResGlobalInfo {
                  xml.HotelReservationIDs {
                    xml.HotelReservationID(:ResID_Type => '501', :ResID_Value => @unique_id)
                    xml.HotelReservationID(:ResID_Type => '502', :ResID_Value => "CTP-#{@unique_id}")
                  }
                }
              }
            }
          }
        }
      }
    end
    builder.to_xml
  end
end