require 'rails_helper'
# NOTE: Using class name here (i.e. describe Admin::PropertyController) makes the app unable to run the view.
describe "Admin::AccountController", :type => :controller do
  include IntegrationTestHelper
  include Capybara::DSL
  # Somehow before :all is loaded before fixtures loaded so we cannot use that.
  before(:each) do
    user = users(:super_admin)
    login_backend user.email, 'testpass'
  end
  describe "create account" do
    it "should be created succesfully." do
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
    end
  end
end