require 'test_helper'
require 'integration/integration_test_helper'
require 'capybara/rails'

class CtripRoomTypeChannelMappingTest < ActionDispatch::IntegrationTest
  include IntegrationTestHelper::Capybara
  include Capybara::DSL
  setup do
    member = members(:super_admin)
    login member.email, 'testpass'
    property = properties(:big_hotel_1)
    select_property property.id
    @property_channel = property_channels(:big_hotel_1_default_ctrip)
  end

  test "Creating a new room type mapping" do
    
  end

  test "Editing a room type mapping" do
    visit "/property_channels/#{@property_channel.id}/edit"
  end

end