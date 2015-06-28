require "rails_helper"
require "connectors/connector.rb"
require "connectors/agoda_connector.rb"

describe "Agoda update inventory spec", :type => :model do
  it 'updates successfully' do
    date_start = Date.today + 1.weeks
    date_end = Date.today + 2.weeks
    property = properties(:big_hotel_1)
    room_type = room_types(:deluxe)
    pool = pools(:default_big_hotel_1)
    rate_type = rate_types(:default)

    # Mapping of updated channel
    updated_connector = AgodaConnector.new(property)

    Inventory.destroy_all
    InventoryLog.destroy_all

    # Set up availabilities in channels to 5 each.
    updated_connector.update_inventories room_type, pool, 5, date_start, date_end

    inventories = updated_connector.get_inventories room_type, date_start, date_end
    expect(inventories[0].total_rooms).to eq(5)

    # Set up availabilities in channels to 4 each.
    updated_connector.update_inventories room_type, pool, 4, date_start, date_end

    inventories = updated_connector.get_inventories room_type, date_start, date_end
    expect(inventories[0].total_rooms).to eq(4)
  end

end