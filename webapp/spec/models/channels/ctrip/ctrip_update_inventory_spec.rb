require "rails_helper"
require "connectors/connector.rb"
require "connectors/ctrip_connector.rb"

describe "Ctrip update inventory spec", :type => :model do
  it 'updates successfully' do
    date_start = Date.today + 1.weeks
    date_end = Date.today + 2.weeks
    property = properties(:big_hotel_1)
    room_type = room_types(:superior)
    pool = pools(:default_big_hotel_1)

    # Mapping of updated channel
    updated_connector = CtripConnector.new(property)

    Inventory.destroy_all
    InventoryLog.destroy_all

    # Set up availabilities in channels to 5 each.
    result = updated_connector.update_inventories room_type, pool, 5, date_start, date_end
    expect(updated_connector.last_inventory_update_successful? result[:unique_id]).to be_truthy
    expect(Inventory.where(
             :room_type_id => room_type.id,
             :pool_id => pool.id,
             :date => date_start,
             :property_id => property.id).first.total_rooms).to eq(5)

    # Making sure the truthy value wasn't by accident by passing some random id and expect
    # it to return falsey.
    expect(updated_connector.last_inventory_update_successful? '01293803').to be_falsey
  end

end