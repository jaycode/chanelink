class AddOrbitzSettingsV5 < ActiveRecord::Migration
  def self.up
    add_column :room_type_channel_mappings, :orbitz_triple_rate_multiplier, :decimal, :precision => 30, :scale => 20
    add_column :room_type_channel_mappings, :orbitz_quad_rate_multiplier, :decimal, :precision => 30, :scale => 20
  end

  def self.down
    remove_column :room_type_channel_mappings, :orbitz_triple_rate_multiplier
    remove_column :room_type_channel_mappings, :orbitz_quad_rate_multiplier
  end
end
