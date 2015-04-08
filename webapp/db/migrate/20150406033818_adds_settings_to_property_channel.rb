class AddsSettingsToPropertyChannel < ActiveRecord::Migration
  def self.up
    # Todo: Perhaps in future we move all channel related data into
    #       some config file.
    add_column :property_channels, :settings, :string, :default => ActiveSupport::JSON.encode({})
  end

  def self.down
    Channel.destroy_all(name: 'Ctrip')

    remove_column :property_channels, :settings
  end
end
