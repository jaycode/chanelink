require 'net/https'

# retrieve and store booking from expedia
class ExpediaBookingHandler < BookingHandler

  def retrieve_and_process(property)

    # retrieve bookings
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.BookingRetrievalRQ('xmlns' => ExpediaChannel::XMLNS_BR_2014, 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance") {
        xml.Authentication(:username => property.expedia_username, :password => property.expedia_password)
        xml.Hotel(:id => property.expedia_hotel_id)
        xml.ParamSet {
          xml.NbDaysInPast '30'
        }
      }
    end

    request_xml = builder.to_xml
    response_xml = ExpediaChannel.post_xml(request_xml, ExpediaChannel::BR)

    # puts response_xml
    
    BookingRetrieval.create(:request_xml => request_xml, :response_xml => response_xml, :property => property, :channel => ExpediaChannel.first)
    
    parse_booking_details_and_store(response_xml, property)
  end

  # parse booking xml and store
  def parse_booking_details_and_store(response, property)
    bookings_xml = Nokogiri::XML(response)
    bookings_data = bookings_xml.xpath("//expedia:Booking", 'expedia' => ExpediaChannel::XMLNS_BR_2014)
    bookings_data.each do |booking_data|
      
      expedia_id = booking_data["id"]
      expedia_type = booking_data['type']

      # if booking already exist in our database and type is not new and do update
      if !Booking.find_by_expedia_booking_id(expedia_id).blank? and expedia_type != ExpediaBooking::TYPE_NEW
        handle_update(booking_data, property)
      elsif !Booking.find_by_expedia_booking_id(expedia_id).blank? and expedia_type == ExpediaBooking::TYPE_NEW
        # do nothing, because booking already in database
      else
        new_booking = ExpediaBooking.new
        new_booking.property = property
        new_booking.channel = channel
        new_booking.status = expedia_type
        new_booking.booking_xml = booking_data.to_s

        # set pool that this current channel currently belongs to
        new_booking.pool = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id).pool

        room_type_data = booking_data.xpath('./expedia:RoomStay', 'expedia' => ExpediaChannel::XMLNS_BR_2014)
        #room_type_map = RoomTypeChannelMapping.find_by_expedia_room_type_id_and_channel_id(room_type_data.attr('roomTypeID').value, channel.id)
        room_type_map = RoomTypeChannelMapping.find_by_channel_id(channel.id)

        puts room_type_data.attr('roomTypeID').value

        # find the room type that this booking correspond to
        if room_type_map
          # new_booking.room_type = room_type_map.room_type
          new_booking.room_type_id = property.room_types[rand(property.room_types.count) - 1].id
        end
        name = booking_data.xpath('.//expedia:PrimaryGuest/expedia:Name', 'expedia' => ExpediaChannel::XMLNS_BR_2014)
        puts name.attr('givenName')

        # construct to become one fullname field
        fullname = ''
        fullname << name.attr('givenName').text if !name.attr('givenName').blank?
        fullname << ' ' + name.attr('middleName').text if !name.attr('middleName').blank?
        fullname << ' ' + name.attr('surname').text if !name.attr('surname').blank?

        new_booking.guest_name = fullname
        new_booking.date_start = booking_data.xpath('.//expedia:StayDate', 'expedia' => ExpediaChannel::XMLNS_BR_2014).attr('arrival').value
        new_booking.date_end = booking_data.xpath('.//expedia:StayDate', 'expedia' => ExpediaChannel::XMLNS_BR_2014).attr('departure').value
        new_booking.booking_date = booking_data['createDateTime']

        new_booking.total_rooms = 1
        new_booking.amount = booking_data.xpath('.//expedia:Total', 'expedia' => ExpediaChannel::XMLNS_BR_2014).attr('amountAfterTaxes').value

        new_booking.expedia_booking_id = booking_data["id"]

        new_booking.save
      end
    end
  end

  def channel
    ExpediaChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  # handle update bookinf data
  def handle_update(booking_data, property)
    expedia_id = booking_data["id"]
    expedia_type = booking_data['type']
    existing_booking = Booking.find_by_expedia_booking_id(expedia_id)

    # do nothing if this xml handled before
    last_booking_xml = Nokogiri::XML(existing_booking.booking_xml)
    return if EquivalentXml.equivalent?(last_booking_xml, booking_data, opts = { :element_order => false, :normalize_whitespace => true })

    # for modification
    if expedia_type == ExpediaBooking::TYPE_MODIFY

      existing_booking.status = expedia_type
      existing_booking.booking_xml = booking_data.to_s

      name = booking_data.xpath('.//expedia:PrimaryGuest/expedia:Name', 'expedia' => ExpediaChannel::XMLNS_BR_2014)

      fullname = ''
      fullname << name.attr('givenName').text if !name.attr('givenName').blank?
      fullname << ' ' + name.attr('middleName').text if !name.attr('middleName').blank?
      fullname << ' ' + name.attr('surname').text if !name.attr('surname').blank?

      existing_booking.guest_name = fullname
      existing_booking.date_start = booking_data.xpath('.//expedia:StayDate', 'expedia' => ExpediaChannel::XMLNS_BR_2014).attr('arrival').value
      existing_booking.date_end = booking_data.xpath('.//expedia:StayDate', 'expedia' => ExpediaChannel::XMLNS_BR_2014).attr('departure').value
      
      existing_booking.amount = booking_data.xpath('.//expedia:Total', 'expedia' => ExpediaChannel::XMLNS_BR_2014).attr('amountAfterTaxes').value
      existing_booking.expedia_confirmed = false
      existing_booking.save
    # for cancellation
    elsif expedia_type == ExpediaBooking::TYPE_CANCEL
      existing_booking.status = expedia_type
      existing_booking.booking_xml = booking_data.to_s
      existing_booking.amount = booking_data.xpath('.//expedia:Total', 'expedia' => ExpediaChannel::XMLNS_BR_2014).attr('amountAfterTaxes').value
      existing_booking.expedia_confirmed = false
      existing_booking.save
    end
  end

end
