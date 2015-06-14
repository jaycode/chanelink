require 'rails_helper'
require 'connectors/connector'
require 'connectors/agoda_connector'
require 'connectors/ctrip_connector'

describe 'Multi Rates Spec' do
  include IntegrationTestHelper

  scenario 'RateType must exist and linked to RateTypePropertyChannel.' do
    rate_type = RateType.first
    expect(rate_type.name).to eq('Default')
    rate_type_property_channel = rate_type_property_channels(:default_big_hotel_1_default_agoda)
    expect(rate_type_property_channel.rate_type.id).to eq(rate_type.id)
  end

  scenario 'RoomTypeMasterRateChannelMapping must be linked to RateTypePropertyChannel.' do
    # RoomTypeMasterRateChannelMapping is like a rule for master rates of given room type,
    # property, and channel, but not the actual rate kept in database.
    # The values and percentage there are values and percentage to be added to master rate
    # when they are used.
    mapping = room_type_master_rate_channel_mappings(:default_big_hotel_1_pool_to_superior_room_in_agoda)
    expect(
        mapping.rate_type_property_channel.id
    ).to eq(rate_type_property_channels(:default_big_hotel_1_default_agoda).id)
  end

  scenario 'RoomTypeChannelMapping must also be linked to RateTypePropertyChannel.' do
    # RoomTypeChannelMapping is the mapping between room type and channel. Somehow the original
    # architecture require this to be separated from RoomTypeMasterRateChannelMapping, which means both of them
    # require linking to RateTypePropertyChannel.
    mapping = room_type_channel_mappings(:superior_agoda)
    expect(
      mapping.rate_type_property_channel.id
    ).to eq(rate_type_property_channels(:default_big_hotel_1_default_agoda).id)
  end

  scenario 'In Agoda channel, get rate types from their server, then set rate_type_property_channel.' do
    rate_type = rate_types(:pay_at_hotel)
    property_channel = property_channels(:big_hotel_1_default_agoda)
    connector = AgodaConnector.new(property_channel.property)
    rate_type_xmls = connector.get_rate_types
    rate_type_property_channel = RateTypePropertyChannel.new(
      :rate_type => rate_type,
      :property_channel => property_channel,
      :settings => {:agoda_rate_plan_id => rate_type_xmls[0].id}
    )
    rate_type_property_channel.save
    expect(rate_type_property_channel.valid?).to eq(true)
  end

  scenario 'In Ctrip channel, get rate plans from app config, then set rate_type_property_channel.' do
    ctrip_connector = CtripConnector.new(properties(:big_hotel_1))
    rate_plans = ctrip_connector.get_rate_types
    expect(rate_plans[0].id).to eq('501')
    expect(rate_plans[1].id).to eq('16')
  end

  scenario "RateTypePropertyChannel should not be able to connect property channel with rate type if they don't belong to same account" do
    # In this scenario, rate plan "pay at hotel" and property channel "another_hotel_1_default_agoda"
    # do not belong under the same account.
    rate_type = rate_types(:pay_at_hotel)
    property_channel = property_channels(:another_hotel_1_default_agoda)
    rate_type_property_channel = RateTypePropertyChannel.new(
      :rate_type => rate_type,
      :property_channel => property_channel
    )
    expect(rate_type_property_channel.valid?).to eq(false)
  end

  scenario 'Getting rates from account must include default rate' do
    account = accounts(:big_hotel_chain)
    rate_types = account.rate_types
    expect(rate_types.count).to eq(2)
  end

end