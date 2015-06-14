require 'rails_helper'
require 'connectors/connector'
require 'connectors/agoda_connector'
require 'connectors/ctrip_connector'

describe 'Multi Rates Spec' do
  include IntegrationTestHelper
  include Capybara::DSL
  before(:each) do
    member = members(:super_admin)
    login member.email, 'testpass'
    @property = properties(:big_hotel_1)
    select_property @property.id
    @pool = pools(:default_big_hotel_1)
  end

  scenario 'Property Channel edit page must show unmapped rooms' do
    visit "property_channels/#{property_channels(:master_rate_mappings_tester_agoda).id}/edit"
    save_and_open_page
    expect(find(:css, ".property_rooms-unmapped-item").count).to eq(2)
  end

  # scenario 'When room_type_master_rate_channel_mapping does not have rate_type_property_channel, ask to create one.' do
  #   Begin by removing rate_type_property_channel from a room_type_master_rate_channel_mapping
  #   mapping = room_type_master_rate_channel_mappings(:default_big_hotel_1_pool_to_superior_room_in_agoda)
  #
  #   visit "/inventories?pool_id=#{@pool.id}"
  #   save_and_open_page
  #   # Expect that page to contain offer to update Agoda rate types.
  #   expect(page).to contain("No rate type mapped")
  # end

  # scenario 'All property channels must be assigned with default rate type when they are first created' do
  #   # Go to property channel creation page, create a property_channel, then see if created property channel
  #   # was assigned with default rate.
  #   visit "/inventories?pool_id=#{@pool_id}"
  # end

  scenario 'Master rates should show multiple rate types in Inventory Grid.' do
  end

  scenario 'Channel rates should show multiple rate types in Inventory Grid.' do
  end

  scenario 'An account can add custom rate plans and assign them to channel rate plans' do
  end

  private

  def erase_room_type_master_rate_mapping_id
    mapping = RoomTypeMasterRateChannelMapping.first(:conditions => {
                                                       :room_type_master_rate_mapping_id => room_type_master_rate_mappings(:default_big_hotel_1_pool_to_superior_room).id,
                                                       :channel_id => channels(:agoda).id
                                                     })
    mapping.rate_type_property_channel_id = nil
    mapping.save
    expect(mapping.valid?).to eq(true)
    mapping = RoomTypeMasterRateChannelMapping.first(:conditions => {
                                                       :room_type_master_rate_mapping_id => room_type_master_rate_mappings(:default_big_hotel_1_pool_to_superior_room).id,
                                                       :channel_id => channels(:agoda).id
                                                     })

    expect(mapping.rate_type_property_channel_id).to be_nil
  end

end