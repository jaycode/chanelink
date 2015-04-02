class CreateRoomTypes < ActiveRecord::Migration
  def self.up
    create_table :room_types do |t|
      t.string :name
      t.decimal :rack_rate, :precision => 8, :scale => 2
      t.decimal :minimum_rate, :precision => 8, :scale => 2
      t.integer :minimum_stay
      t.belongs_to :property
      t.boolean :deleted, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :room_types
  end
end
