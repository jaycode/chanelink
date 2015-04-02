class CreateInventories < ActiveRecord::Migration
  def self.up
    create_table :inventories do |t|
      t.datetime :date
      t.belongs_to :room_type
      t.belongs_to :property
      t.belongs_to :pool
      t.integer :total_rooms
      
      t.timestamps
    end
  end

  def self.down
    drop_table :inventories
  end
end
