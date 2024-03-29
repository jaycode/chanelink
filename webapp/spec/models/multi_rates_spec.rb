require 'rails_helper'
require 'connectors/connector'
require 'connectors/agoda_connector'
require 'connectors/ctrip_connector'

describe 'Multi Rates Spec' do
  include IntegrationTestHelper

  scenario 'Query test' do
    target = room_type_channel_mappings(:superior_agoda)
    mapping = RoomTypeChannelMapping.first(
      :conditions => [
        "ota_room_type_id = ? AND ota_rate_type_id = ?",
        target.ota_room_type_id,
        target.ota_rate_type_id
      ]
    )
    expect(mapping.id).to eq(target.id)
  end

  scenario 'RateType must exists.' do
    rate_type = RateType.first
    expect(rate_type.name).to eq('Default')
  end

  scenario 'RoomTypeMasterRateChannelMapping must be linked to RateType.' do
    # RoomTypeMasterRateChannelMapping is like a rule for master rates of given room type,
    # property, and channel, but not the actual rate kept in database.
    # The values and percentage there are values and percentage to be added to master rate
    # when they are used.
    mapping = room_type_master_rate_channel_mappings(:default_big_hotel_1_pool_to_superior_room_in_agoda)
    expect(
        mapping.rate_type_id
    ).to eq(rate_types(:default).id)
  end

  scenario 'RoomTypeChannelMapping must also be linked to RateType.' do
    # RoomTypeChannelMapping is the mapping between room type and channel. Somehow the original
    # architecture require this to be separated from RoomTypeMasterRateChannelMapping, which means both of them
    # require linking to RateType.
    mapping = room_type_channel_mappings(:superior_agoda)
    expect(
      mapping.rate_type_id
    ).to eq(rate_types(:default).id)
  end

  scenario 'In Agoda channel, get room types from their server, then set room_type_channel_mapping.' do
    rate_type = rate_types(:default)
    property = properties(:another_hotel_1)
    connector = AgodaConnector.new(property)
    room_type_xmls = connector.get_room_types
    room_type_channel_mapping = RoomTypeChannelMapping.new(
      :room_type => room_types(:superior),
      :rate_type => rate_type,
      :channel => channels(:agoda),
      :ota_room_type_id => room_type_xmls[0].id,
      :ota_room_type_name => room_type_xmls[0].name,
      :ota_rate_type_id => room_type_xmls[0].rate_type_id,
      :ota_rate_type_name => room_type_xmls[0].rate_type_name,
      :agoda_single_rate_multiplier => 1
    )
    room_type_channel_mapping.skip_rate_configuration = true
    room_type_channel_mapping.save
    puts room_type_channel_mapping.errors.inspect
    expect(room_type_channel_mapping.valid?).to eq(true)
  end

  scenario 'In Ctrip channel, get rate plans from app config instead of from their server.' do
    ctrip_connector = CtripConnector.new(properties(:another_hotel_1))
    rate_plans = ctrip_connector.get_rate_types
    expect(rate_plans[0].id).to eq('501')
    expect(rate_plans[1].id).to eq('16')
  end

  scenario "RoomRateChannelMapping should not be able to connect property with rate type if they don't belong to same account" do
    # In this scenario, rate plan "pay at hotel" and property channel "another_hotel_1_default_agoda"
    # do not belong under the same account.
    rate_type = rate_types(:pay_at_hotel)
    property = properties(:another_hotel_1)
    connector = AgodaConnector.new(property)
    room_type_xmls = connector.get_room_types
    room_type_channel_mapping = RoomTypeChannelMapping.new(
      :room_type => room_types(:another_superior),
      :rate_type => rate_type,
      :channel => channels(:agoda),
      :ota_room_type_id => room_type_xmls[0].id,
      :ota_room_type_name => room_type_xmls[0].name,
      :ota_rate_type_id => room_type_xmls[0].rate_type_id,
      :ota_rate_type_name => room_type_xmls[0].rate_type_name,
      :agoda_single_rate_multiplier => 1
    )
    room_type_channel_mapping.skip_rate_configuration = true
    room_type_channel_mapping.save
    puts room_type_channel_mapping.errors.inspect
    expect(room_type_channel_mapping.valid?).to eq(false)
  end

  scenario 'Getting rates from account must include default rate' do
    account = accounts(:big_hotel_chain)
    rate_types = account.rate_types
    expect(rate_types.count).to eq(2)
  end

end