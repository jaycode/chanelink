require 'test_helper'

class AgodaChannelTest < ActiveSupport::TestCase
  test "Room Type Fetcher" do
    channel = AgodaChannel.first
    room_types = channel.room_type_fetcher.retrieve(properties(:big_hotel_1))
    assert room_types.count > 0
  end

  test "Inventory Handler" do
    channel = AgodaChannel.first
    
  end

  test "Editing Master Rate" do
      existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(
        today,
        current_property.id,
        params[:pool_id], rt.id
      )
  end
end