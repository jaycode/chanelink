require 'test_helper'
require 'integration/integration_test_helper'
require 'capybara/rails'

class CtripInventoryTest < ActionDispatch::IntegrationTest
  # For prices to be shown in inventories page, following tables must be filled:
  # - properties
  # - pools
  # - room_types
  # - room_type_master_rate_mappings - Needed so master rate inputs can be edited.
  #   Todo: maybe make it so master rate inputs can be edited without having to create an
  #         entry in this table?
  # - room_type_master_rate_channel_mappings - children of room_type_master_rate_mappings.
  #   Todo: room_type_id seems redundant here.
  #
  # With above tables, prices and availabilities for rooms should already be shown,
  # and now we link them to channels by filling in following tables:
  # - channels
  # - room_type_channel_mappings - In here we include room related data from OTAs.
  # - property_channels
  #
  # Room linked with another room, i.e. similar Superior rooms, but one with breakfast,
  # can be added by adding data to this table:
  # - room_type_inventory_links 
  #
  # Data is entered at table inventories.
  include IntegrationTestHelper::WithCapybara
  include Capybara::DSL
  setup do
    member = members(:super_admin)
    login member.email, 'testpass'
    property = properties(:big_hotel_1)
    select_property property.id
    # ADD YOUR CODE HERE:
    #----------------------------------
    @pool_id = pools(:default_big_hotel_1).id
    @channel_id = channels(:ctrip).id
    #----------------------------------
  end

  test "Master Rates update" do
    visit "/inventories?pool_id=#{@pool_id}"
    # Fill in a master price input with a value then save it.
    today = DateTime.now.beginning_of_day.to_date
    room_type = room_types(:superior)
    # puts "element to find: #master_rates-form [name=\"[#{room_type.id}][#{today.to_s}][amount]\"]"
    14.times do |i|
        find(:css, "#master_rates-form [name=\"[#{room_type.id}][#{(today + i).to_s}][amount]\"]").set(300000)
    end
    click_button "master_rates-save"

    save_and_open_page
    # The next page should have all associated channel room prices changed.
    14.times do |i|
      price_cell = find(:css, "#channel_rates-form-#{@channel_id} .dateTableRow .smallColumn:nth-child(#{i+2})")
      assert_equal 300000.0, price_cell.native.text.strip.to_f
    end

  end
end