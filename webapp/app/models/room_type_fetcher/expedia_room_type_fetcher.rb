require 'net/https'

# class to retrieve expedia room types
class ExpediaRoomTypeFetcher < RoomTypeFetcher
  
  def retrieve(property, exclude_mapped_room = false)

    # construct the xml request
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.ProductAvailRateRetrievalRQ('xmlns' => ExpediaChannel::XMLNS_PAR) {
      xml.Authentication(:username => property.expedia_username, :password => property.expedia_password)
      xml.Hotel(:id => property.expedia_hotel_id)
      xml.ParamSet {
        xml.ProductRetrieval
      }
    }
    end

    request_xml = builder.to_xml
    response_xml = ExpediaChannel.post_xml(request_xml, ExpediaChannel::PARR)

    puts response_xml

    room_types = Array.new

    # go through each room types and store it as ExpediaRoomTypeXml
    xml_doc  = Nokogiri::XML(response_xml)
    expedia_room_types = xml_doc.xpath("//expedia:RoomType", 'expedia' => ExpediaChannel::XMLNS_PAR)
    expedia_room_types.each do |rt|
      
      rate_plan_id = rt.xpath(".//expedia:RatePlan", 'expedia' => ExpediaChannel::XMLNS_PAR).first['id']
      
      rt = ExpediaRoomTypeXml.new(rt["id"], rt["name"], rate_plan_id)
      if exclude_mapped_room
        room_types << rt if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:expedia_room_type_id => rt.id, :channel_id => ExpediaChannel.first.id).blank?
      else
        room_types << rt
      end
    end
    room_types
  end

end

