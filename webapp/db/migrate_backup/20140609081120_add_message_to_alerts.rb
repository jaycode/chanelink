class AddMessageToAlerts < ActiveRecord::Migration
  def self.up
    add_column :alerts, :message, :string
    add_column :alerts, :property_id, :integer
  end

  def self.down
    remove_column :alerts, :message, :string
    remove_column :alerts, :property_id, :integer
  end
end
