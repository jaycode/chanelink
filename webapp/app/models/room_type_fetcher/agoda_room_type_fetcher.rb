require 'net/https'

# class to retrieve agoda room types
class AgodaRoomTypeFetcher < RoomTypeFetcher
  include ChannelsHelper
  def retrieve(property, exclude_mapped_room = false)
    room_types = Array.new
    retrieve_xml(property, exclude_mapped_room) do |xml_doc|
    end
    
    # puts '============'
    # puts request_xml
    # puts '============'
    # puts response_xml
    # puts '============'


    room_types
  end

  # Retrieve but in xml format
  def retrieve_xml(property, exclude_mapped_room = false, &block)
    # construct xml to request room type list
    builder = Nokogiri::XML::Builder.new do |xml|
    xml.GetHotelRoomTypesRequest('xmlns' => AgodaChannel::XMLNS) {
      xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
    }
    end

    request_xml = builder.to_xml
    # puts '============'
    # puts request_xml
    # puts '============'
    response_xml = AgodaChannel.post_xml(request_xml)
    # puts response_xml

    # process each room type and form it as our own object
    room_types = Array.new
    xml_doc  = Nokogiri::XML(response_xml)

    status_response = xml_doc.xpath("//agoda:StatusResponse", 'agoda' => AgodaChannel::XMLNS).attr('status').value

    debugger
    if status_response == '200'
      puts "1"
      agoda_room_types = xml_doc.xpath("//agoda:RoomType", 'agoda' => AgodaChannel::XMLNS)
      agoda_room_types.each do |rt|
        rt = AgodaRoomTypeXml.new(rt["RoomTypeID"], rt.text)
        if exclude_mapped_room
          room_types << rt if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:agoda_room_type_id => rt.id, :channel_id => AgodaChannel.first.id).blank?
        else
          room_types << rt
        end
      end
      puts "2"

      # get rate plan for each agoda room type
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.GetHotelRatePlansRequest('xmlns' => AgodaChannel::XMLNS) {
          # Todo: Change this to use settings i.e. property.settings(:hotel_id)
          xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
        }
      end
      puts "3"


      request_xml = builder.to_xml
      response_xml = AgodaChannel.post_xml(request_xml)

      xml_doc = Nokogiri::XML(response_xml)
      debugger
      status_response = xml_doc.xpath("//agoda:StatusResponse", 'agoda' => AgodaChannel::XMLNS).attr('status').value

      if status_response == '200'
        block.call xml_doc
      else
        property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, AgodaChannel.first.id)
        logs_fetching_failure AgodaChannel.first.name, request_xml, xml_doc, property, property_channel, APP_CONFIG[:agoda_endpoint]
      end

    else
      property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, AgodaChannel.first.id)
      logs_fetching_failure AgodaChannel.first.name, request_xml, xml_doc, property, property_channel, APP_CONFIG[:agoda_endpoint]
    end

  end

end
