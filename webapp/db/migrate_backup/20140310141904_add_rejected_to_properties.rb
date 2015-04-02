class AddRejectedToProperties < ActiveRecord::Migration
  def self.up
    add_column :properties, :rejected, :boolean, :default => false
  end

  def self.down
    remove_column :properties, :rejected
  end
end
