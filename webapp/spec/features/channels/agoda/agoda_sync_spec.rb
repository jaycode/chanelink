require 'rails_helper'
require 'connectors/connector'
require 'connectors/agoda_connector'
require 'connectors/ctrip_connector'

describe 'Agoda Sync Spec', :type => :feature do
  include IntegrationTestHelper
  include Capybara::DSL
  scenario 'Should sync availabilities throughout other channels.' do
    date_start = Date.today + 1.weeks
    date_end = Date.today + 2.weeks
    property   = properties(:big_hotel_1)

    # Mapping of updated channel
    updated_mapping = room_type_channel_mappings(:superior_agoda)
    # Mapping of synced channels
    ctrip_mapping = room_type_channel_mappings(:superior_ctrip_room_a)

    # Mapping of updated channel
    updated_connector = AgodaConnector.new(property)
    # Mapping of synced channels
    ctrip_connector = CtripConnector.new(property)

    # Set up availabilities in channels to 5 each.
    updated_connector.update_inventories updated_mapping, 5, date_start, date_end
    ctrip_connector.update_inventories ctrip_mapping, 4, date_start, date_end

    # Let's see if values properly updated.
    inventories = updated_connector.get_inventories updated_mapping, date_start, date_end
    expect(inventories[0].total_rooms).to eq(5)
    # Ctrip has this method to test last update since they update things asynchronously.
    expect(ctrip_connector.last_update_successful?).to eq(true)

    # Imagine that one room in Agoda channel updated to 4.
    updated_connector.update_inventories updated_mapping, 4, date_start, date_end

    # Call the sync action (this should be similar to one inside config/schedule.rb)
    sync

    # Check if other channels' rooms updated if they are in the same pool.
    expect(updated_mapping.room_type.id).to eq(ctrip_mapping.room_type.id)
    expect(PropertyChannel.first(
             :property_id => updated_mapping.room_type.property_id,
             :channel_id => updated_mapping.channel_id
           ).pool_id).to eq(
           PropertyChannel.first(
             :property_id => ctrip_mapping.room_type.property_id,
             :channel_id => ctrip_mapping.room_type.channel_id
           ).pool_id)
    ctrip_inventories = ctrip_connector.get_inventories(ctrip_mapping, date_start, date_end)
    expect(ctrip_inventories[0].total_rooms).to eq(4)
  end
end