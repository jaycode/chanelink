require 'rails_helper'
require 'helpers/ctrip_test_xmls'
require 'helpers/ctrip_reservation_helper'

describe 'Ctrip Reservation Case 9 Spec', :type => :request do
  include IntegrationTestHelper
  include Capybara::DSL

  scenario "[Pay at hotel] with correct credit card" do
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
         xmls.request_900066367(start_date, rtcm),
         {"CONTENT_TYPE" => "text/xml"})

    # See if inventories booked properly.
    saved_inventory = Inventory.find(inventory.id)
    expect(saved_inventory.total_rooms).to eq(29)

    create_log("test_case-9.txt",
               "https://dashboard.chanelink.com#{path}",
               xmls.request_900066367(start_date, rtcm),
               response.body)
  end
end
