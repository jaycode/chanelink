class AddGtaTravelRatePlanIdToRoomTypeChannelMappings < ActiveRecord::Migration
  def self.up
    add_column :room_type_channel_mappings, :gta_travel_rate_plan_id, :string
  end

  def self.down
    remove_column :room_type_channel_mappings, :gta_travel_rate_plan_id
  end
end
