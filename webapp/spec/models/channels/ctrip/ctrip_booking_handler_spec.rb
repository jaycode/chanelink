require "rails_helper"

describe "Ctrip update inventory spec", :type => :model do
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
end

