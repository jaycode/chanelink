class AddDeletedToPropertyChannels < ActiveRecord::Migration
  def self.up
    add_column :property_channels, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :property_channels, :deleted
  end
end
