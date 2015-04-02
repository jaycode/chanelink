class CreateChannelMinStays < ActiveRecord::Migration
  def self.up
    create_table :channel_min_stays do |t|
      t.datetime :date
      t.belongs_to :channel
      t.belongs_to :room_type
      t.belongs_to :property
      t.belongs_to :pool
      t.integer :min_stay
      t.timestamps
    end
  end

  def self.down
    drop_table :channel_min_stays
  end
end
