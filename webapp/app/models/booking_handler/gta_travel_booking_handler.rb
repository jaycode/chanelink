require 'net/https'

# retrieve booking from agoda and store it
class GtaTravelBookingHandler < BookingHandler

  # retrieve booking
  def retrieve_and_process(property)

    property_channel = property.channels.find_by_channel_id(channel.id)

    # build xml request
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_BookingSearchRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001, 'xsi:schemaLocation' => GtaTravelChannel::XMLNS_INVENTORY_UPDATE) {
        GtaTravelChannel.construct_user_element(xml)
        xml.SearchCriteria(:PropertyId => property_channel.gta_travel_property_id, :ArrivalStartDate => date_to_key_short(DateTime.now - 3.days), :ArrivalEndDate => date_to_key_short(DateTime.now + 90.days))
      }
    end

    request_xml = builder.to_xml

    puts request_xml

    response_xml = GtaTravelChannel.post_xml(request_xml, GtaTravelChannel::BOOKING_SEARCH)

    BookingRetrieval.create(:request_xml => request_xml, :response_xml => response_xml, :property => property, :channel => GtaTravelChannel.first)

    puts response_xml

    parse_booking_details_and_store(response_xml, property)
  end

  # store the bookings
  def parse_booking_details_and_store(response, property)
    bookings_xml = Nokogiri::XML(response)
    bookings_datas = bookings_xml.xpath("//gta:Booking", 'gta' => GtaTravelChannel::XMLNS)

    bookings_datas.each do |booking_data|
      status = booking_data["Status"]
      existing_booking_wrap = Booking.find_by_gta_travel_booking_id(booking_data['BookingId'])

      return if !existing_booking_wrap.blank? and status != GtaTravelChannel::TYPE_CONFIRMED

      # a booking can contain multiple room booking
      rooms_datas = booking_data.xpath('//gta:Room', 'gta' => GtaTravelChannel::XMLNS)
      rooms_datas.each do |room_data|

        new_booking = GtaTravelBooking.new
        new_booking.property = property
        new_booking.channel = channel

        new_booking.status = status

        # set pool that this current channel currently belongs to
        new_booking.pool = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id).pool

        room_type_map = RoomTypeChannelMapping.find_by_gta_travel_room_type_id_and_channel_id(room_data["Id"], channel.id)

        # find the room type that this booking correspond to
        if room_type_map
          new_booking.room_type = room_type_map.room_type
        end

        # set the data
        new_booking.guest_name = booking_data['LeadName'];
        new_booking.date_start = booking_data['ArrivalDate'];
        new_booking.date_end = booking_data['DepartureDate'];

        new_booking.total_rooms = room_data['Quantity']
        new_booking.amount = booking_data['TotalCost']

        new_booking.gta_travel_booking_id = booking_data['BookingId']

        # remove payment info element before saving the xml
        new_booking.booking_xml = booking_data.to_s

        new_booking.save
      end
    end
  end

  def channel
    GtaTravelChannel.first
  end

  def date_to_key(date)
    date.strftime('%FT%T')
  end

  def date_to_key_short(date)
    date.strftime('%F')
  end

end
