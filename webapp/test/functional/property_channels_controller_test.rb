require 'test_helper'

class PropertyChannelsControllerTest < ActionController::TestCase
  test "should get page" do
    # This method tests if page can be loaded after logging in.
        
    # Both lines below are required when logging in. In addition, #
    # some pages may require https setup: @request.env['HTTPS'] = 'on'
    login(:super_admin)
    select_property(:big_hotel_1)

    get(:new_wizard_selection)
    assert_response :success
  end

  test "create a new channel" do
    login(:super_admin)
    select_property(:big_hotel_1)
    post(:new_wizard_setting, {:property_channel => {
      :pool_id => pools(:default_big_hotel_1).id,
      :channel_id => channels(:ctrip)}}
    )
    post(:new_wizard_conversion, {
      :property_channel => {
        :ctrip_username => '54394',
        :ctrip_password => 'Ctrip123456'
      }
    })
end