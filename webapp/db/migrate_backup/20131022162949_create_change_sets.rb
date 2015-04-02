class CreateChangeSets < ActiveRecord::Migration
  def self.up
    create_table :change_sets do |t|
      t.string :type
      t.integer :room_type_channel_mapping_id, :references => :room_type_channel_mappings
      t.timestamps
    end
  end

  def self.down
    drop_table :change_sets
  end
end
