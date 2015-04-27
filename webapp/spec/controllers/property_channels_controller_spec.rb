require 'rails_helper'
describe PropertyChannelsController, :type => :controller do
  include IntegrationTestHelper
  include Capybara::DSL
  before(:each) do
    puts "Before All is here!"
    user = users(:super_admin)
    login_backend user.email, 'testpass'
    select_property_backend properties(:big_hotel_1).id
  end
  describe "GET edit" do
    it "should show settings inputs." do
      visit "/backoffic3/properties/#{properties(:big_hotel_1).id}/edit"
      save_and_open_page
    end
  end
end