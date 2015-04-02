require 'net/https'

# class to retrieve booking.com room types
class BookingcomRoomTypeFetcher < RoomTypeFetcher
  
  def retrieve(property, exclude_mapped_room = false)

    # build the xml to request room types
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.request {
        xml.username BookingcomChannel::USERNAME
        xml.password BookingcomChannel::PASSWORD
        xml.hotel_id property.bookingcom_hotel_id
      }
    end

    request_xml = builder.to_xml
    response_xml = BookingcomChannel.post_xml(request_xml, BookingcomChannel::ROOMS)
    
    puts request_xml
    puts response_xml

    room_types = Array.new

    # go through each room types as save date as BookingcomRoomTypeXml
    xml_doc  = Nokogiri::XML(response_xml)
    expedia_room_types = xml_doc.xpath("//room")
    expedia_room_types.each do |rt|
      
      rt = BookingcomRoomTypeXml.new(rt["id"], rt.text(), get_rate_plan_id(property))
      puts rt.rate_plan_id
      
      if exclude_mapped_room
        room_types << rt if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:bookingcom_room_type_id => rt.id, :channel_id => BookingcomChannel.first.id).blank?
      else
        room_types << rt
      end
    end
    room_types
  end

  private

  # fetch rate plan id of a room type
  def get_rate_plan_id(property)
    # construct xml request
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.request {
        xml.username BookingcomChannel::USERNAME
        xml.password BookingcomChannel::PASSWORD
        xml.hotel_id property.bookingcom_hotel_id
      }
    end

    request_xml = builder.to_xml
    response_xml = BookingcomChannel.post_xml(request_xml, BookingcomChannel::RATES)
    puts response_xml
    xml_doc  = Nokogiri::XML(response_xml)
    xml_doc.xpath(".//rate").first['id']
  end

end

