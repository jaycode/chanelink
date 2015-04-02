class CreateChannelMinStayLogs < ActiveRecord::Migration
  def self.up
    create_table :channel_min_stay_logs do |t|
      t.belongs_to :channel_min_stay
      t.integer :min_stay
      t.belongs_to :change_set
      t.timestamps
    end
  end

  def self.down
    drop_table :channel_min_stay_logs
  end
end
