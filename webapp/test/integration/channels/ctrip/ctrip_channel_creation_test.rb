# In our test code files, the lines after ADD_YOUR_CODE_HERE
# are code that are likely to change during creation of each
# channel, but do not follow that as a strict guideline
# i.e. please adjust the any other part of the code as you require.

# See https://github.com/jnicklas/capybara
require 'test_helper'
require 'integration/integration_test_helper'
require 'capybara/rails'

class CtripChannelCreationTest < ActionDispatch::IntegrationTest
  include IntegrationTestHelper::Capybara
  include Capybara::DSL
  setup do
    member = members(:super_admin)
    login member.email, 'testpass'
    property = properties(:big_hotel_3)
    select_property property.id
    # ADD YOUR CODE HERE:
    #----------------------------------
    @property_channel_username = '54394'
    @property_channel_password = 'Ctrip123456'
    @pool_id = pools(:default_big_hotel_3).id
    #----------------------------------
  end

  test "Channel creation" do
    # Todo: Use javascript-enabled testing later - need to figure out error 
    #       "unable to obtain stable firefox connection in 60 seconds (127.0.0.1:7055)".
    #       Maybe we need to open port 7055?
    # Capybara.current_driver = :selenium
    visit '/property_channels/new_wizard_selection'

    # Must select from name, not id
    select(channels(:ctrip).name, :from => 'property_channel_channel_id')
    select(pools(:default_big_hotel_3).name, :from => 'property_channel_pool_id')

    click_button 'property_channel_submit'
    assert_equal '/property_channels/new_wizard_setting', current_path

    # Following are inputs that the property channel must have. They can be created by
    # writing a view file property_channels/_{channel}_setting.html.erb
    #----------------------------------
    # ADD YOUR CODE HERE:
    assert page.has_selector?('#property_channel_settings_username')
    assert page.has_selector?('#property_channel_settings_password')
    #----------------------------------

    fill_in 'property_channel_settings_username', :with => @property_channel_username
    fill_in 'property_channel_settings_password', :with => @property_channel_password
    click_button 'property_channel_submit'
    assert_equal '/property_channels/new_wizard_conversion', current_path

    click_button 'Continue'
    assert_equal '/property_channels/new_wizard_rate_multiplier', current_path

    click_button 'Continue'
    assert_equal '/property_channels/new_wizard_confirm', current_path

    assert page.has_content?(@property_channel_username)
    assert page.has_content?(@property_channel_password)

    click_button 'Finish'
    assert_equal '/property_channels/done_creating', current_path

    click_link 'Click here'
    # Directly open the page instead of selecting and let ajax opens the page.
    visit "/property_channels?pool_id=#{@pool_id}"

    # Capybara.default_wait_time = 10
    # select(@pool_name, :from => 'select_pool')

    assert page.has_content?('Ctrip')
    assert page.has_content?('waiting for approval')

    # Always put this at the bottom so we always know where we're at
    # as we are writing the page:
    # print page.html
    # puts "Current path: #{current_path}"
    # if you'd like to view it on browser, you can do this:
    # save_and_open_page
  end

end