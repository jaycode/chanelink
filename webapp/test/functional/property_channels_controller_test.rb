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

  # More tests on Property Channel are available in test/integration/channels/*_test.rb
end