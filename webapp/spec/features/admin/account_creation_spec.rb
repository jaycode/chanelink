require 'rails_helper'
# NOTE: Using class name here (i.e. describe Admin::PropertyController) makes the app unable to run the view.
describe "Account Creation Spec", :type => :controller do
  include IntegrationTestHelper
  include Capybara::DSL
  # Somehow before :all is loaded before fixtures loaded so we cannot use that.
  before(:each) do
    user = users(:super_admin)
    login_backend user.email, 'testpass'
  end
  describe "create account" do
    it "should be created succesfully." do
      # First step is to create an account and main member for that account
      visit "/backoffic3/accounts/new"
      fill_in 'account_name', :with => "Test Name"
      fill_in 'account_address', :with => 'Test account address 123 123'
      fill_in 'account_telephone', :with => '12313123123'
      fill_in 'account_contact_name', :with => "Account Contact Name"
      fill_in 'account_contact_email', :with => "test@example.com"
      click_button 'account_submit'
      fill_in 'member_name', :with => "Member Name"
      fill_in 'member_email', :with => "test@example.com"
      click_button 'member_submit'
      expect(page).to have_content 'Done creating account'
      new_account = Account.last

      # Now that account created, a property needs to be added to that account, ...
      visit "/backoffic3/properties/new?account_id=#{new_account.id}"
      fill_in 'property_name', :with => "Property Name"
      fill_in 'property_address', :with => "Property Address 123 123"
      fill_in 'property_city', :with => "Surabaya"
      fill_in 'property_state', :with => "Jawa Timur"
      select(countries(:indonesia).name, :from => 'property[country_id]')
      fill_in 'property_postcode', :with => "601123"
      fill_in 'property_minimum_room_rate', :with => "100000"
      fill_in 'property_settings_ctrip_username', :with => properties(:big_hotel_1).settings(:ctrip_username)
      fill_in 'property_settings_ctrip_password', :with => properties(:big_hotel_1).settings(:ctrip_password)
      fill_in 'property_settings_ctrip_hotel_id', :with => properties(:big_hotel_1).settings(:ctrip_hotel_id)
      fill_in 'property_settings_ctrip_code_context', :with => properties(:big_hotel_1).settings(:ctrip_code_context)
      select(currencies(:idr).name, :from => 'property[currency_id]')
      click_button 'property_submit'
      new_property = Property.last

      # ... and a channel needs to be connected to that property, ...
      select_property(new_property.id)
      visit('/backoffic3/property_channels/new')
      select(channels(:ctrip).name, :from => 'property_channel[channel_id]')
      click_button 'Continue'

      click_button 'Continue'

      click_button 'Continue'

      fill_in 'property_channel_rate_conversion_multiplier', :with => '1'
      click_button 'Continue'

      click_button 'Finish'

      new_property_channel = PropertyChannel.last

      # ... and approved ...
      visit "/backoffic3/setup"
      visit "/backoffic3/property_channels/#{new_property_channel.id}/approve"

      # ... so that the property can be approved, ...
      visit "/backoffic3/setup"
      visit "/backoffic3/properties/#{new_property.id}/manage"
      click_button 'Approve'

      # ... and a room type must be created for that property, ...
      visit "/backoffic3/room_types/new"
      fill_in 'room_type_name', :with => 'Test Room Type'
      fill_in 'room_type_rack_rate', :with => '100000'
      click_button 'Save'
      new_room_type = RoomType.last

      # ... that room type must also be connected to a channel, ...
      visit "/backoffic3/dashboard"
      visit "/backoffic3/room_types"
      visit "/backoffic3/room_type_channel_mappings?room_type_id=#{new_room_type.id}"
      visit "/backoffic3/room_type_channel_mappings/new?channel_id=#{channels(:ctrip).id}&room_type_id=#{new_room_type.id}"
      
      # This is how to select option by value:
      within '#room_type_channel_mapping_ctrip_room_rate_plan_code' do
        find("option:nth-child(1)").select_option
      end

      click_button('room_type_channel_mapping_submit')
      click_button('room_type_channel_mapping_submit')
      choose("room_type_channel_mapping_rate_configuration_rack_rate")
      click_button('room_type_channel_mapping_submit')
      check("room_type_channel_mapping_enabled")
      click_button('room_type_channel_mapping_submit')

      # ... so that the account can be activated, then activation email can be sent to email
      # registered with that account.
      visit "/backoffic3/setup"
      visit "/backoffic3/accounts/#{new_account.id}/activate"
      save_and_open_page
      new_account = Account.last
      expect(new_account.approved).to eq(true)
    end
  end
end