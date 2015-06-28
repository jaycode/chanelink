class RemoveRateTypesFromInventories < ActiveRecord::Migration
  def self.up
    remove_column :inventories, :rate_type_id
  end

  def self.down
    add_column :inventories, :rate_type_id, :integer
  end
end
