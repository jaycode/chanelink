require 'test_helper'

class AgodaChannelTest < ActiveSupport::TestCase
  test "Inventory handler" do
    channel = AgodaChannel.first
    room_types = channel.room_type_fetcher.retrieve(properties(:big_hotel_1))
    assert room_types.count > 0
  end
end