require 'test_helper'

class CtripChannelTest < ActiveSupport::TestCase
  test "Default settings" do
    property = properties(:big_hotel_1)
    assert_equal CtripChannel.first.default_settings[:ctrip_company_code], property.settings(:ctrip_company_code)
  end

  test "Inventory handler" do
    channel = CtripChannel.first
    room_types = channel.room_type_fetcher.retrieve(properties(:big_hotel_1))
    puts "room types: #{room_types.inspect}"
    assert(room_types.count > 0)
  end
end