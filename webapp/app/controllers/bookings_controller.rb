require 'net/https'

# controller to handle all booking related
class BookingsController < ApplicationController

  def get
    # confirm booking.com reservation first before retrieving it
    # confirm_bookingcom_reservations

    # go through each property channels and retrieve their bookings
    Property.active_only.each do |property|
      property.channels.each do |pc|
        pc.channel.booking_handler.retrieve_and_process(property) if pc.channel == OrbitzChannel.first
      end
    end

    render :nothing => true
    
  end

  # receive bookings from ctrip
  def get_ctrip
    xml_content = File.read(Rails.root.join('test', 'ctrip_test', '900066252 Creation Request(Postpay Wrong MD5).txt'))
    CtripChannel.first.booking_handler.process(xml_content)

    render :nothing => true
  end

  # method to confirm booking.com reservation
  def confirm_bookingcom_reservations

    # go through all property that connected to booking.com
    PropertyChannel.find_all_by_channel_id(BookingcomChannel.first.id).each do |pc|

      property = pc.property
      next if property.deleted?

      # retrieve all non confirmed bookings
      url = "https://secure-supply-xml.booking.com/hotels/ota/OTA_HotelResNotif?hotel_ids=#{property.bookingcom_hotel_id}"
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(BookingcomChannel::USERNAME, BookingcomChannel::PASSWORD)
      response = http.request(request)
      
      reservation_ids_to_confirm = Array.new

      # go through all the bookings and collect the reservation ids
      response_xml = Nokogiri::XML(response.body)
      reservation_ids = response_xml.xpath("//ns:HotelReservationID", 'ns' => "http://www.opentravel.org/OTA/2003/05")
      reservation_ids.each do |reservation_id|
        reservation_ids_to_confirm << reservation_id['ResID_Value']
      end

      next if reservation_ids_to_confirm.blank?

      # build and XML to confirm booking
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.OTA_HotelResNotifRS('xmlns' => "http://www.opentravel.org/OTA/2003/05", 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance", 'xsi:schemaLocation' => "http://www.opentravel.org/OTA/2003/05 OTA_HotelResNotifRS.xsd", 'TimeStamp' => "2012-10-16T15:39:55", 'Target' => "Production", 'Version' => "2.001") {
          xml.username BookingcomChannel::USERNAME
          xml.password BookingcomChannel::PASSWORD
          xml.hotel_id Property.first.bookingcom_hotel_id
          xml.Success
          xml.HotelReservations {
            xml.HotelReservation {
              xml.ResGlobalInfo {
                xml.HotelReservationIDs {
                  # include all the reservation ids collected before
                  reservation_ids_to_confirm.each do |res|
                    xml.HotelReservationID('ResID_Value' => res, 'ResID_Source' => "BOOKING.COM", 'ResID_Type' => "14")
                    xml.HotelReservationID('ResID_Value' => SecureRandom.hex(10), 'ResID_Source' => "RT", 'ResID_Type' => "14")
                  end
                }
              }
            }
          }
        }
      end

      # send the confirmation
      uri = URI.parse('https://secure-supply-xml.booking.com/hotels/ota/OTA_HotelResNotif')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new(uri.path)
      request.basic_auth(BookingcomChannel::USERNAME, BookingcomChannel::PASSWORD)
      request.body = builder.to_xml
      response = http.request(request)
    end

    render :nothing => true
  end

  def clean_cc_info
    days_to_keep_cc_info = Configuration.first.days_to_keep_cc_info
    
    created_at_start = (DateTime.now - (days_to_keep_cc_info + 3).days).beginning_of_day
    created_at_end = (DateTime.now - (days_to_keep_cc_info).days).beginning_of_day

    Booking.created_at_between(created_at_start, created_at_end).each do |b|
      b.clean_cc_info
    end
    render :nothing => true
  end
  
end
