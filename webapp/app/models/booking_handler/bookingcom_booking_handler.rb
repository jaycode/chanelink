require 'net/https'

# retrieve and store booking.com bookings
class BookingcomBookingHandler < BookingHandler

  def retrieve_and_process(property)

    # retrieve bookings from 24 hours ago
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.request {
        xml.username BookingcomChannel::USERNAME
        xml.password BookingcomChannel::PASSWORD
        xml.hotel_id property.bookingcom_hotel_id
        xml.last_change date_to_key(DateTime.now - 1.day)
      }
    end

    request_xml = builder.to_xml
    response_xml = BookingcomChannel.post_xml(request_xml, BookingcomChannel::RESERVATIONS)
    puts request_xml
    puts response_xml
    BookingRetrieval.create(:request_xml => request_xml, :response_xml => response_xml, :property => property, :channel => BookingcomChannel.first)
    
    parse_booking_details_and_store(response_xml, property)
  end

  # store the bookings
  def parse_booking_details_and_store(response, property)
    bookings_xml = Nokogiri::XML(response)
    bookings_datas = bookings_xml.xpath("//reservation")
    
    bookings_datas.each do |booking_data|
      status = booking_data.xpath('./status').text();
      existing_booking_wrap = Booking.find_by_bookingcom_booking_id(booking_data.xpath('./id').text())

      # handle canceled booking
      if !existing_booking_wrap.blank? and status == BookingcomBooking::TYPE_CANCEL
        handle_cancel(booking_data)
      end

      # a booking can contain multiple room booking
      rooms_datas = booking_data.xpath('./room')
      rooms_datas.each do |room_data|
        bookingcom_room_reservation_id = room_data.xpath('./roomreservation_id').text();
        existing_booking = Booking.find_by_bookingcom_room_reservation_id(bookingcom_room_reservation_id)

        # if booking already exist and marked as modified then do update
        if !existing_booking.blank? and status == BookingcomBooking::TYPE_MODIFY
          handle_update(booking_data, room_data, property)
        elsif !existing_booking.blank? and status == BookingcomBooking::TYPE_NEW
          # do nothing, we already handle this booking
        else
          new_booking = BookingcomBooking.new
          new_booking.property = property
          new_booking.channel = channel
          
          new_booking.bookingcom_room_xml = room_data.to_s
          new_booking.bookingcom_room_reservation_id = bookingcom_room_reservation_id
          new_booking.status = status

          # set pool that this current channel currently belongs to
          new_booking.pool = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id).pool

          room_type_map = RoomTypeChannelMapping.find_by_bookingcom_room_type_id_and_channel_id(room_data.xpath('./id').text(), channel.id)

          # find the room type that this booking correspond to
          if room_type_map
            new_booking.room_type = room_type_map.room_type
          end

          # set the data
          new_booking.guest_name = room_data.xpath('./guest_name').text();
          new_booking.date_start = room_data.xpath('./arrival_date').text();
          new_booking.date_end = room_data.xpath('./departure_date').text();
          new_booking.booking_date = booking_data.xpath('./date').text();

          new_booking.total_rooms = 1
          new_booking.amount = room_data.xpath('./totalprice').text()

          new_booking.bookingcom_booking_id = booking_data.xpath('./id').text()

          # store payment info then remove it from xml element
          new_booking.cc_cvc = booking_data.xpath('./customer/cc_cvc').text();
          booking_data.xpath('./customer/cc_cvc').remove

          new_booking.cc_expiration_date = booking_data.xpath('./customer/cc_expiration_date').text();
          booking_data.xpath('./customer/cc_expiration_date').remove
          
          new_booking.cc_name = booking_data.xpath('./customer/cc_name').text();
          booking_data.xpath('./customer/cc_name').remove

          new_booking.cc_number = booking_data.xpath('./customer/cc_number').text();
          booking_data.xpath('./customer/cc_number').remove

          new_booking.cc_type = booking_data.xpath('./customer/cc_type').text();
          booking_data.xpath('./customer/cc_type').remove

          # remove payment info element before saving the xml
          new_booking.booking_xml = booking_data.to_s

          new_booking.save
        end
      end
    end
  end

  def channel
    BookingcomChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  # handle update of booking
  def handle_update(booking_data, room_data, property)
    bookingcom_room_reservation_id = room_data.xpath('./roomreservation_id').text();
    status = booking_data.xpath('./status').text();
    existing_booking = Booking.find_by_bookingcom_room_reservation_id(bookingcom_room_reservation_id)

    # do nothing if this xml handled before
    last_room_booking_xml = Nokogiri::XML(existing_booking.bookingcom_room_xml)

    puts "#{bookingcom_room_reservation_id} #{status} #{EquivalentXml.equivalent?(last_room_booking_xml, room_data, opts = { :element_order => false, :normalize_whitespace => true })}"
    puts last_room_booking_xml
    puts room_data

    # compare booking xml with the previously stored then do update
    if status == BookingcomBooking::TYPE_MODIFY and !EquivalentXml.equivalent?(last_room_booking_xml, room_data, opts = { :element_order => false, :normalize_whitespace => true })

      existing_booking.status = status
      existing_booking.booking_xml = booking_data.to_s
      existing_booking.bookingcom_room_xml = room_data.to_s

      existing_booking.guest_name = room_data.xpath('./guest_name').text();
      existing_booking.date_start = room_data.xpath('./arrival_date').text();
      existing_booking.date_end = room_data.xpath('./departure_date').text();
      existing_booking.amount = room_data.xpath('./totalprice').text()
      existing_booking.save
    end
  end

  # if type is cancel then find the previous booking record and update the status
  def handle_cancel(booking_data)
    status = booking_data.xpath('./status').text();
    bookingcom_booking_id = booking_data.xpath('./id').text()
    if status == BookingcomBooking::TYPE_CANCEL

      Booking.find_all_by_bookingcom_booking_id(bookingcom_booking_id).each do |existing_booking|

        last_booking_xml = Nokogiri::XML(existing_booking.booking_xml)
        room_reservation_id = booking_data.search("[text()*='#{existing_booking.bookingcom_room_reservation_id}']")

        if room_reservation_id.blank? and !EquivalentXml.equivalent?(last_booking_xml, booking_data, opts = { :element_order => false, :normalize_whitespace => true })
          existing_booking.status = status
          existing_booking.booking_xml = booking_data.to_s

          existing_booking.amount = 0
          existing_booking.save
        end
      end
    end
  end

end
