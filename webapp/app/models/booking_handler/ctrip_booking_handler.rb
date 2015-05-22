require 'net/https'

# retrieve and store booking.com bookings
class CtripBookingHandler < BookingHandler

  # def process(xml)
  #   xml_content = Nokogiri::XML(xml)
  #   hotel_info = xml_content.xpath("//ctrip:BasicPropertyInfo", 'ctrip' => CtripChannel::XMLNS)

  #   # see if it's new or cancel
  #   if xml_content.xpath("//ctrip:OTA_HotelResRQ", 'ctrip' => CtripChannel::XMLNS).count > 0
  #     hotel_code = hotel_info.attr("HotelCode").value
  #     if pc = PropertyChannel.find_by_ctrip_hotel_code(hotel_code)
  #       process_property(xml_content, pc)
  #     else
  #       # hotel not mapped to us, do what?
  #     end
  #   elsif xml_content.xpath("//ctrip:OTA_CancelRQ", 'ctrip' => CtripChannel::XMLNS).count > 0
  #     process_cancel(xml_content, pc)
  #   end
  # end

  # def process_cancel(xml_content, property_channel)
  #   order_node = xml_content.xpath('//ctrip:UniqueID[@Type="501"]', 'ctrip' => CtripChannel::XMLNS)
  #   order_id = order_node.attr('ID').value

  #   cb = CtripBooking.find_by_ctrip_booking_id(order_id)
  #   cb.booking_status = BookingStatus.cancel_type
  #   cb.amount = 0
  #   cb.save
  # end

  # def process_property(xml_content, property_channel)
  #   property = property_channel.property
  #   channel = property_channel.channel

  #   new_booking = CtripBooking.new
  #   new_booking.property = property
  #   new_booking.channel = channel

  #   # set pool that this current channel currently belongs to
  #   new_booking.pool = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id).pool

  #   rate_data = xml_content.xpath('.//ctrip:RoomRate', 'ctrip' => CtripChannel::XMLNS)

  #   # find the chanelink room type that this booking correspond to
  #   room_type_map = RoomTypeChannelMapping.find_by_ctrip_room_rate_plan_code_and_ctrip_room_rate_plan_category(rate_data.attr('RatePlanCode').value, rate_data.attr('RatePlanCategory').value)

  #   if room_type_map and room_type_map.active?
  #     new_booking.room_type = room_type_map.room_type
  #   end

  #   # set all the data into our own booking object
  #   person_name = xml_content.xpath('.//ctrip:PersonName', 'ctrip' => CtripChannel::XMLNS)
  #   new_booking.guest_name = person_name.xpath('.//ctrip:GivenName', 'ctrip' => CtripChannel::XMLNS).text + " " + xml_content.xpath('.//ctrip:Surname', 'ctrip' => CtripChannel::XMLNS).text

  #   timespan = xml_content.xpath('.//ctrip:TimeSpan', 'ctrip' => CtripChannel::XMLNS)
  #   new_booking.date_start = timespan.attr('Start').value
  #   new_booking.date_end = timespan.attr('End').value
    
  #   new_booking.booking_date = DateTime.now

  #   new_booking.total_rooms = rate_data.attr('NumberOfUnits').value
  #   new_booking.amount = xml_content.xpath('.//ctrip:Total', 'ctrip' => CtripChannel::XMLNS).attr('AmountAfterTax').value

  #   new_booking.ctrip_booking_id = xml_content.xpath('.//ctrip:UniqueID[@Type="501"]', 'ctrip' => CtripChannel::XMLNS).attr('ID').value
  #   new_booking.booking_xml = xml_content

  #   new_booking.save
  #   puts new_booking.errors
  # end

  # store into our own booking object
  def retrieve_and_process_by_bookings_data(bookings_data, property)
    bookings_data.each do |booking_data|

      new_booking           = CtripBooking.new
      new_booking.property  = property
      new_booking.channel   = channel

      # set pool that this current channel currently belongs to
      new_booking.pool      = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id).pool

      # find the chanelink room type that this booking correspond to
      room_type_map         = RoomTypeChannelMapping.find(:first, 
        :conditions => [
          "(settings LIKE ? AND settings LIKE ?) OR (ctrip_room_rate_plan_code = ? AND ctrip_room_rate_plan_category = ?)", 
          '%"ctrip_room_rate_plan_code": "' + booking_data[:rate_plan_code].to_s + '"%', 
          '%"ctrip_room_rate_plan_category": "' + booking_data[:rate_plan_category].to_s + '"%',
          booking_data[:rate_plan_code].to_s,
          booking_data[:rate_plan_category].to_s
      ])
      if room_type_map and room_type_map.active?
        new_booking.room_type = room_type_map.room_type
      end

      # set all the data into our own booking object
      new_booking.guest_name        = booking_data[:guest_name]
      new_booking.date_start        = booking_data[:date_start]
      new_booking.date_end          = booking_data[:date_end]
      new_booking.booking_date      = booking_data[:booking_date]

      new_booking.total_rooms       = booking_data[:total_rooms]
      new_booking.amount            = booking_data[:amount]

      # new_booking.ctrip_booking_id  = booking_data[:ctrip_booking_id]

      new_booking.save
    end
  end

  def channel
    CtripChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end
  
end
