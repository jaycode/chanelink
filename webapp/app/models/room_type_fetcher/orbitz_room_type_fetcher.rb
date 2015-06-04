require 'net/https'

# class to retrieve ctrip room types
class OrbitzRoomTypeFetcher < RoomTypeFetcher

  def retrieve(property, exclude_mapped_room = false)
    property_channel = PropertyChannel.find_by_property_id_and_channel_id(property.id, OrbitzChannel.first.id)

    # construct xml to request room type list
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.OWW_HotelRoomRatePlanGetRQ(:xmlns => OrbitzChannel::XMLNS) {
        OrbitzChannel.construct_auth_element(xml)
        xml.RoomRatePlan {
          xml.HotelCriteria(:ChainCode => property_channel.orbitz_chain_code, :HotelCode => property_channel.orbitz_hotel_code)
        }
      }
    end

    request_xml = builder.to_xml
    response_xml = OrbitzChannel.post_xml(request_xml, OrbitzChannel::ROOM_RATE_FETCH)

    # process each room type and form it as our own object
    room_types = Array.new

    xml_doc  = Nokogiri::XML(response_xml)
    orbitz_room_types = xml_doc.xpath("//orbitz:RoomTypes/orbitz:RoomType", 'orbitz' => OrbitzChannel::XMLNS)
    orbitz_room_types.each do |rt|
      description = rt.xpath(".//orbitz:Description", 'orbitz' => OrbitzChannel::XMLNS).text()
      puts rt["RoomTypeCode"]
      
      room_type = OrbitzRoomTypeXml.new(rt["RoomTypeCode"], description)

      if exclude_mapped_room
        room_types << room_type if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:orbitz_room_type_id => rt["RoomTypeCode"], :channel_id => OrbitzChannel.first.id).blank?
      else
        room_types << room_type
      end
    end
    room_types
  end

end
