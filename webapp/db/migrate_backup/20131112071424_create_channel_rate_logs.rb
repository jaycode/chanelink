class CreateChannelRateLogs < ActiveRecord::Migration
  def self.up
    create_table :channel_rate_logs do |t|
      t.belongs_to :channel_rate
      t.decimal :amount, :precision => 8, :scale => 2
      t.belongs_to :change_set
      t.timestamps
    end
  end

  def self.down
    drop_table :channel_rate_logs
  end
end
