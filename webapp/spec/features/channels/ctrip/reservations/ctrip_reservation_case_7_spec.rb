require 'rails_helper'
require 'helpers/ctrip_test_xmls'
require 'helpers/ctrip_reservation_helper'

# This is a cancellation of case 2, so we run that case first prior to cancelling.
describe 'Ctrip Reservation Case 7 Spec', :type => :request do
  include IntegrationTestHelper
  include Capybara::DSL

  scenario "Online Modification: [Pay at hotel] modify guest(add one guest)" do
    xmls = CtripTestXmls.new
    start_date = Date.today + 1.weeks
    rtcm = room_type_channel_mappings(:superior_ctrip_room_a)

    # First setup the inventory needed.
    Inventory.destroy_all
    Booking.destroy_all

    inventory = Inventory.new
    inventory.date = start_date
    inventory.total_rooms = 30
    inventory.room_type_id = rtcm.room_type_id
    inventory.property = rtcm.room_type.property
    inventory.pool_id = pools(:default_big_hotel_1).id

    inventory.save

    path = "/api/soap/ctrip"
    post(path,
         xmls.creation_request_900066342(start_date, rtcm),
         {"CONTENT_TYPE" => "text/xml"})

    # Expect the response to follow the spec.
    response_xml = Nokogiri::XML(response.body).xpath(
      '//ctrip:OTA_HotelResRQ', 'ctrip' => CtripChannel::XMLNS).children
    target_xml = Nokogiri::XML(xmls.creation_response_900066342).xpath(
      '//ctrip:OTA_HotelResRQ', 'ctrip' => CtripChannel::XMLNS).children
    # Removes all whitespaces and newlines
    expect(response_xml.to_xml.gsub(/\s+/, "")).to eq(target_xml.to_xml.gsub(/\s+/, ""))

    # See if inventories booked properly.
    saved_inventory = Inventory.find(inventory.id)
    expect(saved_inventory.total_rooms).to eq(29)

    # Now try to cancel that order.
    path = "/api/soap/ctrip"
    post(path,
         xmls.cancellation_request_900066342,
         {"CONTENT_TYPE" => "text/xml"})

    # Expect the response to follow the spec.
    response_xml = Nokogiri::XML(response.body).xpath(
      '//ctrip:OTA_CancelRS', 'ctrip' => CtripChannel::XMLNS).children
    target_xml = Nokogiri::XML(xmls.cancellation_response_900066342).xpath(
      '//ctrip:OTA_CancelRS', 'ctrip' => CtripChannel::XMLNS).children
    # Removes all whitespaces and newlines
    expect(response_xml.to_xml.gsub(/\s+/, "")).to eq(target_xml.to_xml.gsub(/\s+/, ""))

    # See if inventories reverted properly.
    saved_inventory = Inventory.find(inventory.id)
    expect(saved_inventory.total_rooms).to eq(30)

    create_log("test_case-7a.txt",
               "https://dashboard.chanelink.com#{path}",
               xmls.cancellation_request_900066342,
               response.body)
    # Now modify
    post(path,
         xmls.creation_request_900066345(start_date, rtcm),
         {"CONTENT_TYPE" => "text/xml"})

    # Expect the response to follow the spec.
    response_xml = Nokogiri::XML(response.body).xpath(
      '//ctrip:OTA_HotelResRQ', 'ctrip' => CtripChannel::XMLNS).children
    target_xml = Nokogiri::XML(xmls.creation_response_900066345).xpath(
      '//ctrip:OTA_HotelResRQ', 'ctrip' => CtripChannel::XMLNS).children
    # Removes all whitespaces and newlines
    expect(response_xml.to_xml.gsub(/\s+/, "")).to eq(target_xml.to_xml.gsub(/\s+/, ""))

    # See if inventories reverted properly.
    saved_inventory = Inventory.find(inventory.id)
    expect(saved_inventory.total_rooms).to eq(29)

    create_log("test_case-7b.txt",
               "https://dashboard.chanelink.com#{path}",
               xmls.creation_request_900066345(start_date, rtcm),
               response.body)
  end
end
