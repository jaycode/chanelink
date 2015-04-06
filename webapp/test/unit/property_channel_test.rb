require 'test_helper'

class PropertyChannelTest < ActiveSupport::TestCase
  test "settings" do
    property_channel = PropertyChannel.new do |p|
      p.property = properties(:big_hotel_1)
      p.channel = channels(:ctrip)
      p.pool = pools(:default_big_hotel_1)
    end
    property_channel.settings = {:agoda => {:id => 'agoda-id'}, :ctrip => {:id => 'the-id'}}
    assert_equal 'the-id', property_channel.settings(:ctrip, :id)

    # These are needed when saving a new property channel.
    property_channel.skip_channel_specific = true
    property_channel.skip_rate_conversion_multiplier = true

    property_channel.settings = {:agoda => {:id => 'agoda-id2'}}
    property_channel.save

    saved_property_channel = PropertyChannel.find_by_id(property_channel.id)
    assert_equal 'agoda-id2', saved_property_channel.settings(:agoda, :id)

    saved_property_channel.destroy_settings
    assert saved_property_channel.settings(:__default).empty?
  end
end