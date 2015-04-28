require 'rails_helper'
describe PropertyChannelsController, :type => :controller do
  include IntegrationTestHelper
  include Capybara::DSL
  # Somehow before :all is loaded before fixtures loaded so we cannot use that.
  before(:each) do
    user = users(:super_admin)
    login_backend user.email, 'testpass'
    select_property_backend properties(:big_hotel_1).id
  end
  describe "GET edit" do
    it "should show settings inputs." do
      visit "/backoffic3/properties/#{properties(:big_hotel_1).id}/edit"
      fill_in 'property_settings_ctrip_hotel_id', :with => "testvalue"
      click_button 'property_submit'
      expect(page).to have_content 'testvalue'
      save_and_open_page
    end
  end
end