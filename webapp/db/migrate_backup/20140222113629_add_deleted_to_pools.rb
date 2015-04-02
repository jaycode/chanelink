class AddDeletedToPools < ActiveRecord::Migration
  def self.up
    add_column :pools, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :pools, :deleted
  end
end
