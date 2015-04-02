require 'net/https'

class TiketcomRoomTypeFetcher < RoomTypeFetcher
  
  def retrieve(property, exclude_mapped_room = false)

    property_channel = PropertyChannel.find_by_property_id_and_channel_id(property.id, TiketcomChannel.first.id)
    
    response_xml = TiketcomChannel.send_request(TiketcomChannel::ROOM_TYPES, property_channel.tiketcom_hotel_key)

    puts response_xml

    room_types = Array.new

#    xml_doc  = Nokogiri::XML(response_xml)
#    expedia_room_types = xml_doc.xpath("//expedia:RoomType", 'expedia' => ExpediaChannel::XMLNS_PAR)
#    expedia_room_types.each do |rt|
#
#      rate_plan_id = rt.xpath(".//expedia:RatePlan", 'expedia' => ExpediaChannel::XMLNS_PAR).first['id']
#
#      rt = ExpediaRoomTypeXml.new(rt["id"], rt["name"], rate_plan_id)
#      if exclude_mapped_room
#        room_types << rt if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:expedia_room_type_id => rt.id, :channel_id => ExpediaChannel.first.id).blank?
#      else
#        room_types << rt
#      end
#    end
    room_types
  end

end

