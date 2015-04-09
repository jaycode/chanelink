# See https://github.com/jnicklas/capybara
require 'test_helper'
require 'integration/integration_test_helper'
require 'capybara/rails'

class CtripChannelCreationTest < ActionDispatch::IntegrationTest
  # We don't want to include :property_channels in our fixtures,
  # so don't use fixtures :all
  fixtures :accounts, :channels, :countries, :member_roles, :members, :pools, :properties
  include IntegrationTestHelper::Capybara
  include Capybara::DSL
  setup do
    member = members(:super_admin)
    login member.email, 'testpass'
    property = properties(:big_hotel_1)
    select_property property.id
    @property_channel_username = '54394'
    @property_channel_password = 'Ctrip123456'
  end

  test "Channel creation" do
    visit '/property_channels/new_wizard_selection'

    # Must select from name, not id
    select(channels(:ctrip).name, :from => 'property_channel_channel_id')
    select(pools(:default_big_hotel_1).name, :from => 'property_channel_pool_id')

    click_button 'property_channel_submit'
    assert_equal current_path, '/property_channels/new_wizard_setting'

    # Following are inputs that the property channel must have. They can be created by
    # writing a view file property_channels/_{channel}_setting.html.erb
    #----------------------------------
    assert page.has_selector?('#property_channel_settings_username')
    assert page.has_selector?('#property_channel_settings_password')
    #----------------------------------

    fill_in 'property_channel_settings_username', :with => @property_channel_username
    fill_in 'property_channel_settings_password', :with => @property_channel_password
    click_button 'property_channel_submit'
    assert_equal current_path, '/property_channels/new_wizard_conversion'

    click_button 'property_channel_submit'
    assert_equal current_path, '/property_channels/new_wizard_rate_multiplier'

    click_button 'property_channel_submit'
    assert_equal current_path, '/property_channels/new_wizard_rate_confirm'

    click_button 'property_channel_submit'
    assert_equal current_path, '/property_channels/done_creating'

    click_link 'Click here'
    assert_equal current_path, '/property_channels'
    assert page.has_content('Ctrip')
    assert page.has_content('waiting for approval')

    # Always put this at the bottom so we always know where we're at
    # as we are writing the page:
    print page.html
    puts "Current path: #{current_path}"
    # if you'd like to view it on browser, you can do this:
    save_and_open_page
  end
end