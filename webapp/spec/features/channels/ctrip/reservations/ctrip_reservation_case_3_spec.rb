require 'rails_helper'
require 'helpers/ctrip_test_xmls'
require 'helpers/ctrip_reservation_helper'

describe 'Ctrip Reservation Case 3 Spec', :type => :request do
  # include RSpec::Rails::ControllerExampleGroup
  include IntegrationTestHelper
  include Capybara::DSL

  scenario "Offline Creation:28 day+20 rooms+[Pay at hotel]+5 guests+selected Items in special request part(try to arrange double bed & try to arrange non-smoking room) + No free text" do
    xmls = CtripTestXmls.new
    start_date = Date.today + 1.weeks
    rtcm = room_type_channel_mappings(:superior_ctrip_room_a)

    # First setup the inventory needed.
    Inventory.destroy_all
    inventory_ids = []

    # The last day is omitted.
    start_date.upto(start_date + 27.days) do |date|
      inventory = Inventory.new
      inventory.date = date
      inventory.total_rooms = 30
      inventory.room_type_id = rtcm.room_type_id
      inventory.property = rtcm.room_type.property
      inventory.pool_id = pools(:default_big_hotel_1).id

      inventory.save
      inventory_ids << inventory.id
    end

    path = "/api/soap/ctrip"
    post(path,
         xmls.creation_request_900066321(start_date, rtcm),
         {"CONTENT_TYPE" => "text/xml"})

    # See if inventories updated properly.
    inventory_ids.each do |inventory_id|
      saved_inventory = Inventory.find(inventory_id)
      expect(saved_inventory.total_rooms).to eq(10)
    end

    # Expect the response to follow the spec.
    response_xml = Nokogiri::XML(response.body).xpath(
      '//ctrip:OTA_HotelResRS', 'ctrip' => CtripChannel::XMLNS).children
    target_xml = Nokogiri::XML(xmls.creation_response_900066321).xpath(
      '//ctrip:OTA_HotelResRS', 'ctrip' => CtripChannel::XMLNS).children
    # Removes all whitespaces and newlines
    expect(response_xml.to_xml.gsub(/\s+/, "")).to eq(target_xml.to_xml.gsub(/\s+/, ""))
    create_log("test_case-3.txt",
               "https://dashboard.chanelink.com#{path}",
               xmls.creation_request_900066321(start_date, rtcm),
               response.body)
  end
end
