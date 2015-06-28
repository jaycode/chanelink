require 'net/https'

# retrieve booking from agoda and store it
class AgodaBookingHandler < BookingHandler
  include ChannelsHelper

  # days: How many days in the past?
  def get_bookings_xml(property, days, &block)
    booking_ids = get_booking_ids(property, days)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GetBookingDetailsRequest('xmlns' => AgodaChannel::XMLNS) {
        xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
        xml.BookingIDList {
          booking_ids.each do |booking_id|
            puts booking_id
            xml.BookingID booking_id
          end
        }
      }
    end

    request_xml = builder.to_xml
    response_xml = AgodaChannel.post_xml(request_xml)

    xml_doc  = Nokogiri::XML(response_xml)
    begin
      success = xml_doc.xpath('//agoda:StatusResponse', 'agoda' => AgodaChannel::XMLNS).attr('status').value
      # 204 is when no inventory returned.
      if success == '200' or success == '204'
        block.call xml_doc
      else
        property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id)
        logs_get_bookings_failure channel.name, request_xml, xml_doc, property, property_channel, APP_CONFIG[:agoda_endpoint]
      end
    rescue
      property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id)
      logs_get_bookings_failure channel.name, request_xml, xml_doc, property, property_channel, APP_CONFIG[:agoda_endpoint]
    end
  end

  def get_booking_ids(property, days)
    booking_ids = Array.new
    get_booking_ids_xml(property, days) do |xml_doc|
      bookings = xml_doc.xpath("//agoda:Booking/agoda:BookingID", 'agoda' => AgodaChannel::XMLNS)
      bookings.each do |booking|
        booking_ids << booking.inner_text
      end
    end
    booking_ids
  end
  def get_booking_ids_xml(property, days, &block)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GetBookingListRequest('xmlns' => AgodaChannel::XMLNS) {
        xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
        xml.DateRange(:Type => "Stay", :Start => date_to_key(Date.today - days.days), :End => date_to_key(Date.today))
        xml.RequestType 'ConfirmBooking'
      }
    end
    request_xml = builder.to_xml
    response_xml = AgodaChannel.post_xml(request_xml)

    BookingRetrieval.create(
      :request_xml => request_xml,
      :response_xml => response_xml,
      :property => property,
      :channel => AgodaChannel.first
    )

    xml_doc  = Nokogiri::XML(response_xml)
    begin
      success = xml_doc.xpath('//agoda:StatusResponse', 'agoda' => AgodaChannel::XMLNS).attr('status').value
      # 204 is when no inventory returned.
      if success == '200' or success == '204'
        block.call xml_doc
      else
        property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id)
        logs_get_bookings_failure channel.name, request_xml, xml_doc, property, property_channel, APP_CONFIG[:agoda_endpoint]
      end
    rescue
      property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id)
      logs_get_bookings_failure channel.name, request_xml, xml_doc, property, property_channel, APP_CONFIG[:agoda_endpoint]
    end
  end

  protected
  # store into our own booking object
  def parse_booking_details_and_store(response, property)
    new_bookings = []
    bookings_data = response.xpath("//agoda:BookingDetailData", 'agoda' => AgodaChannel::XMLNS)
    bookings_data.each do |booking_data|
      puts booking_data
      new_booking = AgodaBooking.new
      new_booking.property = property
      new_booking.channel = channel

      # set pool that this current channel currently belongs to
      new_booking.pool = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id).pool

      room_type_data = booking_data.xpath('./agoda:RoomType', 'agoda' => AgodaChannel::XMLNS)

      # find the chanelink room type that this booking correspond to
      room_type_map = RoomTypeChannelMapping.find_by_ota_room_type_id(room_type_data.attr('RoomTypeID').value)

      puts room_type_data.attr('RoomTypeID').value
      if room_type_map and room_type_map.active?
        new_booking.room_type = room_type_map.room_type
      end

      # set all the data into our own booking object
      new_booking.guest_name = booking_data.xpath('./agoda:Guests/agoda:Guest/agoda:Name', 'agoda' => AgodaChannel::XMLNS).text
      new_booking.date_start = booking_data.xpath('./agoda:DateRange', 'agoda' => AgodaChannel::XMLNS).attr('Start').value
      new_booking.date_end = booking_data.xpath('./agoda:DateRange', 'agoda' => AgodaChannel::XMLNS).attr('End').value
      new_booking.booking_date = booking_data.xpath('./agoda:BookingDate', 'agoda' => AgodaChannel::XMLNS).text

      new_booking.total_rooms = booking_data.xpath('./agoda:NoOfRoom', 'agoda' => AgodaChannel::XMLNS).text
      new_booking.amount = booking_data.xpath('./agoda:Rates', 'agoda' => AgodaChannel::XMLNS).attr('inclusive').value

      new_booking.agoda_booking_id = booking_data.xpath('./agoda:BookingID', 'agoda' => AgodaChannel::XMLNS).text

      if new_booking.save
        new_bookings << new_booking
      else
        new_bookings << AgodaBooking.find_by_agoda_booking_id(new_booking.agoda_booking_id)
      end
    end
    new_bookings
  end

  def channel
    AgodaChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  

end
