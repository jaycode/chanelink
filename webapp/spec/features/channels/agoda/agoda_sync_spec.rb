require 'rails_helper'

describe 'Agoda Sync Spec', :type => :feature do
  include IntegrationTestHelper
  include Capybara::DSL
  scenario 'Should sync availabilities throughout other channels.' do
    date_start = Date.today + 1.weeks
    date_end = Date.today + 2.weeks
    channel_to_update = AgodaChannel.first
    channels_to_test_sync = [CtripChannel.first]
    pool       = pools(:default_big_hotel_1)
    property   = properties(:big_hotel_1)
    room_type  = room_types(:superior)

    # Set up availabilities in channels to 5 each.
    date_start.upto(date_end) do |date|
      existing_inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(date, property.id, pool.id, room_type.id)
      existing_inv.update_attribute(:total_rooms, 5)

      log = create_inventory_log(existing_inv)
      change_set = InventoryChangeSet.create
      log.update_attribute(:change_set_id, change_set.id)
      channel_to_update.inventory_handler.create_job(change_set, false)
    end

    # Imagine that one room in Agoda channel updated to 4.

    # Call the sync action (this should be similar to one inside config/schedule.rb)

    # Check if other channels' rooms updated.
  end
end