require 'net/https'

# class to retrieve agoda room types
class AgodaRoomTypeFetcher < RoomTypeFetcher
  
  def retrieve(property, exclude_mapped_room = false)

    # construct xml to request room type list
    builder = Nokogiri::XML::Builder.new do |xml|
    xml.GetHotelRoomTypesRequest('xmlns' => AgodaChannel::XMLNS) {
      xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
    }
    end

    request_xml = builder.to_xml
    response_xml = AgodaChannel.post_xml(request_xml)
    puts response_xml

    # process each room type and form it as our own object
    room_types = Array.new
    xml_doc  = Nokogiri::XML(response_xml)
    agoda_room_types = xml_doc.xpath("//agoda:RoomType", 'agoda' => AgodaChannel::XMLNS)
    agoda_room_types.each do |rt|
      rt = AgodaRoomTypeXml.new(rt["RoomTypeID"], rt.text)
      if exclude_mapped_room
        room_types << rt if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:agoda_room_type_id => rt.id, :channel_id => AgodaChannel.first.id).blank?
      else
        room_types << rt
      end
    end

    # get rate plan for each agoda room type
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GetHotelRatePlansRequest('xmlns' => AgodaChannel::XMLNS) {
        # Todo: Change this to use settings i.e. property.settings(:hotel_id)
        # Todo: 
        xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
      }
    end

    request_xml = builder.to_xml
    response_xml = AgodaChannel.post_xml(request_xml)
    puts response_xml


    room_types
  end

end
