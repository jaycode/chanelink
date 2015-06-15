require 'net/https'

class AgodaRoomTypeFetcher < RoomTypeFetcher
  include ChannelsHelper
  def retrieve(property, exclude_mapped_rooms = false)
    room_types = Array.new
    retrieve_xml(property) do |xml_doc|
      rate_types = AgodaChannel.first.rate_type_fetcher.retrieve(property)
      agoda_room_types = xml_doc.xpath('//agoda:RoomType', 'agoda' => AgodaChannel::XMLNS)
      agoda_room_types.each do |room_type|

        rate_types.each do |rate_type|
          rt = RoomTypeXml.new(
            room_type['RoomTypeID'],
            room_type.text,
            rate_type.id,
            rate_type.name,
            room_type.to_s,
            rate_type.content)
          if exclude_mapped_rooms
              if RoomTypeChannelMapping.first(
                :conditions => {
                  :ota_room_type_id => room_type['RoomTypeID'],
                  :ota_rate_type_id => rate_type.id,
                  :channel_id => AgodaChannel.first.id
                }).blank?
                room_types << rt
              end
          else
            room_types << rt
          end
        end
      end
    end
    room_types
  end
  def retrieve_xml(property, &block)
    request_xml = request(property).to_xml
    response_xml = AgodaChannel.post_xml(request_xml)
    xml_doc  = Nokogiri::XML(response_xml)

    status_response = xml_doc.xpath('//agoda:StatusResponse', 'agoda' => AgodaChannel::XMLNS).attr('status').value

    if status_response == '200'
      block.call xml_doc
    else
      property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, AgodaChannel.first.id)
      logs_fetching_failure AgodaChannel.first.name, request_xml, xml_doc, property, property_channel, APP_CONFIG[:agoda_endpoint]
    end
  end

  def request(property)
    Nokogiri::XML::Builder.new do |xml|
      xml.GetHotelRoomTypesRequest('xmlns' => AgodaChannel::XMLNS) {
        xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
      }
    end
  end
end
