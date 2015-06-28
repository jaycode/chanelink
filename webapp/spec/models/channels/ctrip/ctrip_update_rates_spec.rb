require "rails_helper"
require "connectors/connector.rb"
require "connectors/ctrip_connector.rb"

describe "Ctrip update rates spec", :type => :model do
  it 'updates successfully' do
    date_start = Date.today + 1.weeks
    date_end = Date.today + 2.weeks
    property = properties(:big_hotel_1)
    room_type = room_types(:superior)
    rate_type = rate_types(:default)
    pool = pools(:default_big_hotel_1)

    # Mapping of updated channel
    updated_connector = CtripConnector.new(property)

    MasterRate.destroy_all
    MasterRateLog.destroy_all

    # Set up rates in channels to 100 each.
    result = updated_connector.update_rates room_type, rate_type, pool, 100, date_start, date_end
    expect(updated_connector.last_rate_update_successful? result[:unique_id]).to be_truthy

    # Making sure the truthy value wasn't by accident by passing some random id and expect
    # it to return falsey.
    expect(updated_connector.last_rate_update_successful? '01293803').to be_falsey
  end
end