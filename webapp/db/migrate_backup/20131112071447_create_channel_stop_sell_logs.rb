class CreateChannelStopSellLogs < ActiveRecord::Migration
  def self.up
    create_table :channel_stop_sell_logs do |t|
      t.belongs_to :channel_stop_sell
      t.boolean :stop_sell
      t.belongs_to :change_set
      t.timestamps
    end
  end

  def self.down
    drop_table :channel_stop_sell_logs
  end
end
