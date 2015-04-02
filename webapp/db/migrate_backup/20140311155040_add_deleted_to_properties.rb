class AddDeletedToProperties < ActiveRecord::Migration
  def self.up
    add_column :properties, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :properties, :deleted
  end
end
