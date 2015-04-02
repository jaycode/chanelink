class CreateChannelCtdLogs < ActiveRecord::Migration
  def self.up
    create_table :channel_ctd_logs do |t|
      t.belongs_to :channel_ctd
      t.boolean :ctd
      t.belongs_to :change_set
      t.timestamps
    end
  end

  def self.down
    drop_table :channel_ctd_logs
  end
end
