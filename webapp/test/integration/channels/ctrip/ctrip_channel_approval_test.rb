require 'test_helper'
require 'integration/integration_test_helper'
require 'capybara/rails'

class CtripChannelApprovalTest < ActionDispatch::IntegrationTest
  fixtures :accounts, :channels, :countries, :member_roles, :members, :pools, :properties
  include IntegrationTestHelper::Capybara
  include Capybara::DSL
  setup do
    member = members(:super_admin)
    login member.email, 'testpass'
    property = properties(:big_hotel_1)
    select_property property.id
    # ADD YOUR CODE HERE:
    #----------------------------------
    @property_channel_username = '54394'
    @property_channel_password = 'Ctrip123456'
    #----------------------------------
  end
end