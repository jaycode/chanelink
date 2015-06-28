require "rails_helper"
require "connectors/connector.rb"
require "connectors/agoda_connector.rb"

describe "Agoda update rates spec", :type => :model do
  it 'updates successfully' do
    date_start = Date.today + 1.weeks
    date_end = Date.today + 2.weeks
    property = properties(:big_hotel_1)
    room_type = room_types(:superior)
    rate_type = rate_types(:default)
    pool = pools(:default_big_hotel_1)

    # Mapping of updated channel
    updated_connector = AgodaConnector.new(property)

    MasterRate.destroy_all
    MasterRateLog.destroy_all

    # Set up rates in channels to 400000 each.
    updated_connector.update_rates room_type, rate_type, pool, 400000, date_start, date_end

    rates = updated_connector.get_rates room_type, rate_type, date_start, date_end
    expect(rates[0].total_rooms).to eq(400000)

    # Set up rates in channels to 500000 each.
    updated_connector.update_rates room_type, rate_type, pool, 500000, date_start, date_end

    rates = updated_connector.get_rates room_type, rate_type, date_start, date_end
    expect(rates[0].total_rooms).to eq(500000)
  end
end