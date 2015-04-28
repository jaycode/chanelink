require 'rails_helper'
describe Admin::PropertiesController, :type => :controller do
  include IntegrationTestHelper
  include Capybara::DSL
  # Somehow before :all is loaded before fixtures loaded so we cannot use that.
  before(:each) do
    user = users(:super_admin)
    login_backend user.email, 'testpass'
    select_property_backend properties(:big_hotel_1).id
  end
  describe "edit and update" do
    it "should show settings inputs." do
      save_and_open_page
      visit "/backoffic3/properties/#{properties(:big_hotel_1).id}/edit"
      save_and_open_page
      fill_in 'property_settings_ctrip_hotel_id', :with => "testvalue"
      click_button 'property_submit'
      save_and_open_page
      expect(page).to have_content 'testvalue'
    end
  end
end