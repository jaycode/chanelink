class AddsSettingsToProperties < ActiveRecord::Migration
  def self.up
    add_column :properties, :settings, :string, :default => ActiveSupport::JSON.encode({})
  end
  def self.down
    remove_column :properties, :settings
  end
end
