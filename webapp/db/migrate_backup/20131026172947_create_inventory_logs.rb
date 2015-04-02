class CreateInventoryLogs < ActiveRecord::Migration
  def self.up
    create_table :inventory_logs do |t|
      t.belongs_to :inventory
      t.belongs_to :booking
      t.string :type
      t.integer :total_rooms
      t.belongs_to :change_set
      t.timestamps
    end
  end

  def self.down
    drop_table :inventory_logs
  end
end
