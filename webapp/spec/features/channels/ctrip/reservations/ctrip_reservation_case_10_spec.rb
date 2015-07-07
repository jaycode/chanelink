require 'rails_helper'
require 'helpers/ctrip_test_xmls'
require 'helpers/ctrip_reservation_helper'

describe 'Ctrip Reservation Case 10 Spec', :type => :request do
  include IntegrationTestHelper
  include Capybara::DSL

  scenario "Prepay with corrupted MD5 string" do
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
         xmls.request_900066252(start_date, rtcm),
         {"CONTENT_TYPE" => "text/xml"})

    # Expect the response to follow the spec.
    response_xml = Nokogiri::XML(response.body).xpath(
      '//ctrip:OTA_CancelRS', 'ctrip' => CtripChannel::XMLNS).children
    target_xml = Nokogiri::XML(xmls.response_900066252).xpath(
      '//ctrip:OTA_CancelRS', 'ctrip' => CtripChannel::XMLNS).children
    # Removes all whitespaces and newlines
    expect(response_xml.to_xml.gsub(/\s+/, "")).to eq(target_xml.to_xml.gsub(/\s+/, ""))

    # See if inventories reverted properly.
    saved_inventory = Inventory.find(inventory.id)
    expect(saved_inventory.total_rooms).to eq(30)

    create_log("test_case-10.txt",
               "https://dashboard.chanelink.com#{path}",
               xmls.request_900066252(start_date, rtcm),
               response.body)
  end
end
