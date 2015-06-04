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
      # Todo: Might be better to directly use pool_id than room_type_master_rate_mapping_id?
      mapping = RoomTypeMasterRateChannelMapping.find_by_room_type_master_rate_mapping_id_and_channel_id_and_room_type_id(
        room_type_master_rate_mappings(:room_type_to_channel_mapping_tester).id,
        channels(:agoda).id,
        room_types(:superior).id)
      expect(mapping).not_to be_nil
      visit "/inventories?pool_id=#{pools(:test_big_hotel_1_for_testing_master_rate_mapping).id}"
      price_cell = find(:css, "#channel_rates-form-#{channels(:agoda).id} #agoda_room_type-#{room_types(:superior).id} .smallColumn:nth-child(#{2})")
      expect(price_cell.text).to eq("0.0")
    end
    it "should show input boxes under each room type when master rate not connected to room type." do
      mapping = RoomTypeMasterRateChannelMapping.find_by_room_type_master_rate_mapping_id_and_channel_id_and_room_type_id(
        room_type_master_rate_mappings(:room_type_to_channel_mapping_tester).id,
        channels(:ctrip).id,
        room_types(:superior).id)
      expect(mapping).to be_nil
      visit "/inventories?pool_id=#{pools(:test_big_hotel_1_for_testing_master_rate_mapping).id}"
      price_cell = find(:css, "#channel_rates-form-#{channels(:ctrip).id} #ctrip_room_type-#{room_types(:superior).id} .smallColumn:nth-child(#{2}) > input")
      expect(price_cell.value).to eq("0")
    end
  end
end