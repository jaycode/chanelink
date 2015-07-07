require 'rails_helper'
require 'helpers/ctrip_test_xmls'
require 'helpers/ctrip_reservation_helper'

describe 'Ctrip Reservation Case 4 Spec', :type => :request do
  include IntegrationTestHelper
  include Capybara::DSL

  scenario "Online Creation:2 days+1 room+Prepay+2 guests +selected Items(try to arrange double bed & try to arrange non-smoking room)+ free text(text is \"Test Reservation\")" do
    # In this scenario we try to rent a room that is connected to another room
    # i.e. Superior Room w/ Double Bed that connects to Superior Room
    # BUT
    # There is no way to currently find out how to get list of available options, so let's skip this.

    xmls = CtripTestXmls.new
    start_date = Date.today + 1.weeks
    rtcm = room_type_channel_mappings(:superior_ctrip_room_a)

    # First setup the inventory needed.
    Inventory.destroy_all
    inventory_ids = []

    # The last day is omitted.
    start_date.upto(start_date + 1.days) do |date|
      inventory = Inventory.new
      inventory.date = date
      inventory.total_rooms = 5
      inventory.room_type_id = rtcm.room_type_id
      inventory.property = rtcm.room_type.property
      inventory.pool_id = pools(:default_big_hotel_1).id

      inventory.save
      inventory_ids << inventory.id
    end

    path = "/api/soap/ctrip"
    post(path,
         xmls.creation_request_900066362(start_date, rtcm),
         {"CONTENT_TYPE" => "text/xml"})

    # See if inventories updated properly.
    inventory_ids.each do |inventory_id|
      saved_inventory = Inventory.find(inventory_id)
      expect(saved_inventory.total_rooms).to eq(4)
    end

    # Expect the response to follow the spec.
    response_xml = Nokogiri::XML(response.body).xpath(
      '//ctrip:OTA_HotelResRS', 'ctrip' => CtripChannel::XMLNS).children
    target_xml = Nokogiri::XML(xmls.creation_response_900066362).xpath(
      '//ctrip:OTA_HotelResRS', 'ctrip' => CtripChannel::XMLNS).children
    # Removes all whitespaces and newlines
    expect(response_xml.to_xml.gsub(/\s+/, "")).to eq(target_xml.to_xml.gsub(/\s+/, ""))
    create_log("test_case-4.txt",
               "https://dashboard.chanelink.com#{path}",
               xmls.creation_request_900066362(start_date, rtcm),
               response.body)
  end
end
