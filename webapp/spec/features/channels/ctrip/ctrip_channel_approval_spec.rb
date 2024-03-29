require 'rails_helper'

describe 'Ctrip Channel Approval Spec' do
  include IntegrationTestHelper
  include Capybara::DSL
  before(:each) do
    user = users(:super_admin)
    login_backend user.email, 'testpass'
    select_property_backend properties(:big_hotel_2).id
  end

  # Todo: Finish this method.
  scenario "Approving a channel" do
    property_channel = property_channels(:unapproved)
    visit("/backoffic3/property_channels/#{property_channel.id}/approve")
    assert page.has_content?(I18n.t('admin.properties.approve.message.success'))

    # Todo: Find out why saved instance does not get stored in the database.
    # save_and_open_page
    # property_channel = PropertyChannel.first(:conditions => {:id => property_channel.id})
    # puts property_channel.inspect
    # assert property_channel.approved
    
  end

end