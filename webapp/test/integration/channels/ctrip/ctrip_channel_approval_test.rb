require 'test_helper'
require 'integration/integration_test_helper'
require 'capybara/rails'

class CtripChannelApprovalTest < ActionDispatch::IntegrationTest
  fixtures :accounts, :channels, :countries, :member_roles, :members, :pools, :properties, :property_channels, :users
  include IntegrationTestHelper::Capybara
  include Capybara::DSL
  setup do
    user = users(:super_admin)
    login_backend user.email, 'testpass'
  end

  # Todo: Finish this method.
  test "Approving a channel" do
    property_channel = property_channels(:unapproved)
    visit('/property_channels/approve')
    click('approve button')
    assert property_channel.approved
  end

end