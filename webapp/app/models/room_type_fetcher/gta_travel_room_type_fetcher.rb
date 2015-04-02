require 'net/https'

class GtaTravelRoomTypeFetcher < RoomTypeFetcher
  
  def retrieve(property, exclude_mapped_room = false)

    property_channel = PropertyChannel.find_by_property_id_and_channel_id(property.id, GtaTravelChannel.first.id)
    
    retrieve_contract(property_channel)

    # construct the xml request
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_RoomsReadRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001) {
        GtaTravelChannel.construct_user_element(xml)
        xml.Property(:Id => property_channel.gta_travel_property_id)
      }
    end

    request_xml = builder.to_xml
    Rails.logger.info request_xml

    response_xml = GtaTravelChannel.post_xml(request_xml, GtaTravelChannel::ROOM_READ)

    Rails.logger.info response_xml

    room_types = Array.new

    xml_doc  = Nokogiri::XML(response_xml)
    gta_travel_room_types = xml_doc.xpath("//gtatravel:Room", 'gtatravel' => GtaTravelChannel::XMLNS)
    gta_travel_room_types.each do |rt|

      room_type = GtaTravelRoomTypeXml.new(rt["Id"], rt["Description"], rt["RateBasis"], rt["MaxOccupancy"])
      
      if exclude_mapped_room
        room_types << room_type if RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:gta_travel_room_type_id => rt["Id"], :channel_id => GtaTravelChannel.first.id).blank?
      else
        room_types << room_type
      end
    end
    room_types
  end

  def retrieve_contract(property_channel)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_ContractReadRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001) {
        GtaTravelChannel.construct_user_element(xml)
        xml.Property(:Id => property_channel.gta_travel_property_id)
      }
    end

    request_xml = builder.to_xml
    response_xml = GtaTravelChannel.post_xml(request_xml, GtaTravelChannel::CONTRACT_READ)
    Rails.logger.info request_xml
    Rails.logger.info response_xml
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_PropertyReadRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001) {
        GtaTravelChannel.construct_user_element(xml)
      }
    end

    request_xml = builder.to_xml
    response_xml = GtaTravelChannel.post_xml(request_xml, GtaTravelChannel::PROPERTY_READ)
    Rails.logger.info request_xml
    Rails.logger.info response_xml

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_PropertyDetailsReadRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001) {
        GtaTravelChannel.construct_user_element(xml)
        xml.Property(:Id => property_channel.gta_travel_property_id)
      }
    end

    request_xml = builder.to_xml
    response_xml = GtaTravelChannel.post_xml(request_xml, GtaTravelChannel::PROPERTY_DETAILS_READ)
    Rails.logger.info request_xml
    Rails.logger.info response_xml
  end

end

