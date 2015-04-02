class AddOrbitzSettingsV2 < ActiveRecord::Migration
  def self.up
    add_column :room_type_channel_mappings, :orbitz_single_rate_multiplier, :decimal, :precision => 30, :scale => 20
    add_column :room_type_channel_mappings, :orbitz_double_rate_multiplier, :decimal, :precision => 30, :scale => 20
    add_column :room_type_channel_mappings, :orbitz_rate_plan_id, :string
  end

  def self.down
    remove_column :room_type_channel_mappings, :orbitz_single_rate_multiplier
    remove_column :room_type_channel_mappings, :orbitz_double_rate_multiplier
    remove_column :room_type_channel_mappings, :orbitz_rate_plan_id
  end
end
