class AddOrbitzSettingsV3 < ActiveRecord::Migration
  def self.up
    add_column :room_type_channel_mappings, :orbitz_additional_guest_amount, :decimal, :precision => 30, :scale => 20
  end

  def self.down
    remove_column :room_type_channel_mappings, :orbitz_additional_guest_amount
  end
end
