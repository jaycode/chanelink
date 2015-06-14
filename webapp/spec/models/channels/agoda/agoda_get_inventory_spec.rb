require "rails_helper"
require "helpers/agoda_spec_helper"

describe "Agoda get inventory spec", :type => :model do
  include AgodaConnector
  before(:each) do
    @channel    = AgodaChannel.first
    @pool       = pools(:default_big_hotel_1)
    @property   = properties(:big_hotel_1)
    @room_type  = room_types(:superior)
  end

  it 'gets inventory availabilities successfully' do
    date_start                = Date.today + 1.weeks
    date_end                  = Date.today + 2.weeks
    total_rooms_alternatives  = [6, 7]
    total_rooms_before        = get_inventories(@channel, @property, @pool, @room_type, date_start, date_end)
  end
end