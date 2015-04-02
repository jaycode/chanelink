require 'net/https'

# retrieve booking from orbitz and store it
class OrbitzBookingHandler < BookingHandler

  # retrieve booking
  def retrieve_and_process(property)

    property_channel = property.channels.find_by_channel_id(channel.id)

    # build xml request
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.OTA_ReadRQ(:xmlns => OrbitzChannel::XMLNS) {
        OrbitzChannel.construct_auth_element(xml)
        xml.ReadRequests {
          xml.HotelReadRequest(:ChainCode => "TEST", :HotelCode => "314") {
            xml.SelectionCriteria(:Start => date_to_key(DateTime.now - 13.days), :End => date_to_key(DateTime.now))
          }
        }
      }
    end

    request_xml = builder.to_xml
    response_xml = OrbitzChannel.post_xml(request_xml, OrbitzChannel::OTHER)

    puts response_xml

    xml_doc  = Nokogiri::XML(response_xml)
    BookingRetrieval.create(:request_xml => request_xml, :response_xml => response_xml, :property => property, :channel => OrbitzChannel.first)

    # after retrieving for the list, now must retrieve for more detailed
    response = retrieve_all_booking_details(xml_doc, property)

    # parse all booking data and store it
    parse_booking_details_and_store(response, property)
  end

  # retrieve more detailed booking data
  def retrieve_all_booking_details(xml_doc, property)
    bookings = xml_doc.xpath("//orbitz:HotelReservationSummary/orbitz:ConfirmID", 'orbitz' => OrbitzChannel::XMLNS)
    booking_ids = Array.new
    bookings.each do |booking|
      booking_ids << booking["ID"]
    end

    # build xml request
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.OTA_ReadRQ(:xmlns => OrbitzChannel::XMLNS) {
        OrbitzChannel.construct_auth_element(xml)
        xml.ReadRequests {
          booking_ids.each do |booking_id|
            xml.ReadRequest {
              xml.ConfirmID(:ID => booking_id, :Type => 'Orbitz')
            }
          end
        }
      }
    end

    request_xml = builder.to_xml
    response_xml = OrbitzChannel.post_xml(request_xml, OrbitzChannel::OTHER)
    puts response_xml

    Nokogiri::XML(response_xml)
  end

  # store into our own booking object
  def parse_booking_details_and_store(response, property)
    bookings_data = response.xpath("//orbitz:HotelReservationDetail", 'orbitz' => OrbitzChannel::XMLNS)
    bookings_data.each do |booking_data|
      puts booking_data
      new_booking = OrbitzBooking.new
      new_booking.property = property
      new_booking.channel = channel

      # set pool that this current channel currently belongs to
      new_booking.pool = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id).pool

      room_type_data = booking_data.xpath('./orbitz:Room', 'orbitz' => OrbitzChannel::XMLNS)

      # find the chanelink room type that this booking correspond to
      room_type_map = RoomTypeChannelMapping.find_by_orbitz_room_type_id(room_type_data.attr('InvCode').value)

      if room_type_map and room_type_map.active?
        new_booking.room_type = room_type_map.room_type
      end

      # set all the data into our own booking object
      guest = booking_data.xpath('./orbitz:Guest', 'orbitz' => OrbitzChannel::XMLNS)
      new_booking.guest_name = "#{guest.attr("GivenName")} #{guest.attr("Surname")}"
      new_booking.date_start = booking_data['CheckinDate']
      new_booking.date_end = booking_data['CheckoutDate']
      new_booking.booking_date = booking_data['BookingDate']

      new_booking.total_rooms = booking_data.xpath('./orbitz:RoomCount', 'orbitz' => OrbitzChannel::XMLNS).text
      new_booking.amount = booking_data.xpath('./orbitz:Pricing/orbitz:Total/orbitz:SupplierRate', 'orbitz' => OrbitzChannel::XMLNS).text

      new_booking.orbitz_booking_id = booking_data.xpath('./orbitz:ConfirmID', 'orbitz' => OrbitzChannel::XMLNS).attr("ID")

      # remove payment info element before saving the xml
      new_booking.booking_xml = booking_data.to_s

      new_booking.save
    end
  end

  def channel
    OrbitzChannel.first
  end

  def date_to_key(date)
    date.strftime('%FT%T')
  end

  

end
