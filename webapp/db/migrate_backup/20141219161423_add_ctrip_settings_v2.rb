class AddCtripSettingsV2 < ActiveRecord::Migration
  def self.up
    add_column :room_type_channel_mappings, :ctrip_room_type_name, :string
    add_column :room_type_channel_mappings, :ctrip_room_rate_plan_category, :string
    add_column :room_type_channel_mappings, :ctrip_room_rate_plan_code, :string
  end

  def self.down
    remove_column :room_type_channel_mappings, :ctrip_room_type_name
    remove_column :room_type_channel_mappings, :ctrip_room_rate_plan_category
    remove_column :room_type_channel_mappings, :ctrip_room_rate_plan_code
  end
end
