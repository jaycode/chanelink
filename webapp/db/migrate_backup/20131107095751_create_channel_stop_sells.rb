class CreateChannelStopSells < ActiveRecord::Migration
  def self.up
    create_table :channel_stop_sells do |t|
      t.datetime :date
      t.belongs_to :channel
      t.belongs_to :room_type
      t.belongs_to :property
      t.belongs_to :pool
      t.boolean :stop_sell
      t.timestamps
    end
  end

  def self.down
    drop_table :channel_stop_sells
  end
end
