require 'rails_helper'
require 'helpers/ctrip_test_xmls'
require 'helpers/ctrip_reservation_helper'

describe 'Ctrip Reservation Case 1 Spec', :type => :request do
  # include RSpec::Rails::ControllerExampleGroup
  include IntegrationTestHelper
  include Capybara::DSL

  scenario "Online Creation:1 day+1 room+[Pay at hotel]+1 guest+No free text, expect order created" do
    xmls = CtripTestXmls.new
    date = Date.today + 1.weeks
    rtcm = room_type_channel_mappings(:superior_ctrip_room_a)

    # First setup the inventory needed.
    Inventory.destroy_all
    inventory = Inventory.new
    inventory.date = date
    inventory.total_rooms = 10
    inventory.room_type_id = rtcm.room_type_id
    inventory.property = rtcm.room_type.property
    inventory.pool_id = pools(:default_big_hotel_1).id

    inventory.save

    # This post request would order a room from Ctrip, adjust the inventories accordingly
    # post '/api/soap/ctrip', :data => xmls.creation_request_900066242(date, rtcm)
    path = "/api/soap/ctrip"
    post(path,
         xmls.creation_request_900066242(date, rtcm),
         {"CONTENT_TYPE" => "text/xml"})

    # See if inventories updated properly.
    saved_inventory = Inventory.find(inventory.id)
    expect(saved_inventory.total_rooms).to eq(9)

    # Expect the response to follow the spec.
    response_xml = Nokogiri::XML(response.body).xpath(
      '//ctrip:OTA_HotelResRS', 'ctrip' => CtripChannel::XMLNS).children
    target_xml = Nokogiri::XML(xmls.creation_response_900066242).xpath(
      '//ctrip:OTA_HotelResRS', 'ctrip' => CtripChannel::XMLNS).children
    # Removes all whitespaces and newlines
    expect(response_xml.to_xml.gsub(/\s+/, "")).to eq(target_xml.to_xml.gsub(/\s+/, ""))
    create_log("test_case-1.txt",
               "https://dashboard.chanelink.com#{path}",
               xmls.creation_request_900066242(date, rtcm),
               response.body)
  end
end
