require 'rails_helper'

describe 'HasSettings', :type => :model do
  scenario 'settings creation and removal' do
    property_channel = PropertyChannel.new do |p|
      p.property = properties(:big_hotel_1)
      p.channel = channels(:ctrip)
      p.pool = pools(:default_big_hotel_1)
    end
    property_channel.settings = {:username => 'username', :password => 'password'}
    assert_equal 'username', property_channel.settings(:username)

    # These are needed when saving a new property channel.
    property_channel.skip_channel_specific = true
    property_channel.skip_rate_conversion_multiplier = true

    # Various ways you can set settings up.
    property_channel.settings = {:something => {:is => 'nothing'}}
    property_channel.settings = {:something_else => 'none'}
    property_channel.settings = nil
    property_channel.settings = ""
    property_channel.settings = {:json_value => true}.to_json
    property_channel.save

    saved_property_channel = PropertyChannel.find_by_id(property_channel.id)
    assert_equal 'nothing', saved_property_channel.settings(:something, :is)
    assert_equal 'none', saved_property_channel.settings(:something_else)
    assert_equal true, saved_property_channel.settings(:json_value)

    saved_property_channel.destroy_settings
    # puts 'settings is #{saved_property_channel.settings().inspect}'
    assert saved_property_channel.settings().empty?
  end

  scenario 'undefined settings should return empty string' do
    property_channel = property_channels(:big_hotel_1_default_ctrip)
    assert_equal nil, property_channel.settings(:undefined, :setting)
  end

  scenario 'update settings with update_attributes' do
    property_channel = property_channels(:big_hotel_1_default_ctrip)
    property_channel.update_attributes({:settings => {:this => 'that'}})
    expect(property_channel.settings(:this)).to eq('that')
  end

  scenario 'update if empty' do
    property_channel = property_channels(:big_hotel_1_default_ctrip)
    property_channel.settings = ({:empty => '', :not_empty => 'yay'})
    property_channel.update_empty_settings({:empty => 'value', :not_empty => 'value', :undefined => 'value'})
    expect(property_channel.settings(:empty)).to eq('value')
    expect(property_channel.settings(:undefined)).to eq('value')
    expect(property_channel.settings(:not_empty)).to eq('yay')
  end
end