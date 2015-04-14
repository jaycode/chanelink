class AddsSettingsToPropertyChannels < ActiveRecord::Migration
  def self.up
    add_column :property_channels, :settings, :string, :default => ActiveSupport::JSON.encode({})
  end

  def self.down
    remove_column :property_channels, :settings
  end
end
