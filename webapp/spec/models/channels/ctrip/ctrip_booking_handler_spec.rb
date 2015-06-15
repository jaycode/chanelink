require "rails_helper"

describe "Ctrip update inventory spec", :type => :model do
  scenario 'Query test' do
    target = room_type_channel_mappings(:superior_agoda)
    mapping = RoomTypeChannelMapping.first(
      :conditions => [
        "ota_room_type_id = ? AND rate_type_property_channels.ota_rate_type_id = ?",
        target.ota_room_type_id,
        target.rate_type_property_channel.ota_rate_type_id
      ],
      :joins => ['LEFT JOIN rate_type_property_channels ON '+
                   'rate_type_property_channel_id = rate_type_property_channels.id']
    )
    expect(mapping.id).to eq(target.id)
  end
end

