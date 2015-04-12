require 'test_helper'
require 'integration/integration_test_helper'
require 'capybara/rails'

class CtripChannelApprovalTest < ActionDispatch::IntegrationTest
  include IntegrationTestHelper::Capybara
  include Capybara::DSL
  setup do
    user = users(:super_admin)
    login_backend user.email, 'testpass'
  end

  # Todo: Finish this method.
  test "Approving a channel" do
    property_channel = property_channels(:unapproved)
    visit("/property_channels/#{property_channel.id}/approve")
    assert property_channel.approved
  end

end