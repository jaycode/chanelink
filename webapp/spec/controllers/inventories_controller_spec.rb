require 'rails_helper'
# NOTE: Using class name here (i.e. describe InventoriesController) makes the app unable to run the view.
describe "InventoriesController", :type => :controller do
  include IntegrationTestHelper
  include Capybara::DSL
  before(:each) do
    member = members(:super_admin)
    login member.email, 'testpass'
    select_property properties(:big_hotel_1).id
  end
  describe "connection between master rates and input boxes" do
    # To understand this, see that when room_type_master_rate_channel_mapping
    # exists for a certain channel and room type, text boxes will not show.
    # See test/fixtures/pools.yml
    it "should not show input boxes under each room type when master rate connected to room type." do
      mapping = RoomTypeMasterRateChannelMapping.find_by_room_type_master_rate_mapping_id_and_channel_id_and_room_type_id_and_rate_type_id(
        room_type_master_rate_mappings(:room_type_to_channel_mapping_tester).id,
        channels(:agoda).id,
        room_types(:superior).id,
        rate_types(:default).id)
      expect(mapping).not_to be_nil
      visit "/inventories?pool_id=#{pools(:test_big_hotel_1_for_testing_master_rate_mapping).id}"
      finder = "#channel_rates-form-#{channels(:agoda).id} #agoda_room_type-#{room_types(:superior).id}_rate_type-#{rate_types(:default).id} .smallColumn:nth-child(#{2})"
      price_cell = find(:css, finder)
      expect(price_cell.text).to eq("0.0")
    end
    it "should show input boxes under each room type when master rate not connected to room type." do
      mapping = RoomTypeMasterRateChannelMapping.find_by_room_type_master_rate_mapping_id_and_channel_id_and_room_type_id_and_rate_type_id(
        room_type_master_rate_mappings(:room_type_to_channel_mapping_tester).id,
        channels(:ctrip).id,
        room_types(:superior).id,
        rate_types(:default).id)
      expect(mapping).to be_nil
      visit "/inventories?pool_id=#{pools(:test_big_hotel_1_for_testing_master_rate_mapping).id}"
      finder = "#channel_rates-form-#{channels(:ctrip).id} #ctrip_room_type-#{room_types(:superior).id}_rate_type-#{rate_types(:default).id} .smallColumn:nth-child(#{2}) > input"
      price_cell = find(:css, finder)
      expect(price_cell.value).to eq("0")
    end
  end

  scenario 'Updating an inventory should be reflected in database.' do
    Inventory.destroy_all
    InventoryLog.destroy_all

    pool = pools(:test_big_hotel_1_for_testing_master_rate_mapping)
    room_type = room_types(:deluxe)
    rate_type = rate_types(:default)
    today = DateTime.now.beginning_of_day.to_date.to_s

    set_inventory_to(10, pool, room_type, today)
    # REMEMBER KIDS!:
    # It's never the cache issue. When your html doesn't show what you expected, it is wrong. Simple as that.
    # Rails.cache.clear
    # ActiveRecord::Base.connection.query_cache.clear
    set_inventory_to(12, pool, room_type, today)
  end

  def set_inventory_to(rooms, pool, room_type, date)
    visit "/inventories?pool_id=#{pool.id}"
    text_finder = "#inventories-form input[name=\"[#{room_type.id}][#{date}]\"]"
    inventory_input = find(:css, text_finder)
    inventory_input.set(rooms)
    button_finder = "#inventories-form input[name=\"commit\"]"
    save_button = find(:css, button_finder)
    save_button.click
    inventory = Inventory.first(
      :conditions => {
        :date => date,
        :pool_id => pool.id,
        :room_type_id => room_type.id
      }
    )
    expect(inventory.total_rooms).to eq(rooms)
    inventory_input = find(:css, text_finder)
    expect(inventory_input.value).to eq(rooms.to_s)
  end
end