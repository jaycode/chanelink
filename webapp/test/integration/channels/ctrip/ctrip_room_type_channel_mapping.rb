require 'test_helper'
require 'integration/integration_test_helper'
require 'capybara/rails'

class CtripRoomTypeChannelMappingTest < ActionDispatch::IntegrationTest
  include IntegrationTestHelper::WithCapybara
  include Capybara::DSL
  setup do
    member = members(:super_admin)
    login member.email, 'testpass'
    property = properties(:big_hotel_1)
    select_property property.id
    @property_channel = property_channels(:big_hotel_1_default_ctrip)
    @room_type = room_types(:superior)
  end

  test "Mapping a Chanelink's room to OTA's" do
    visit "/room_type_channel_mappings/new?property_channel_id=#{@property_channel.id}&room_type_id=#{@room_type.id}"
    save_and_open_page
  end
  
end