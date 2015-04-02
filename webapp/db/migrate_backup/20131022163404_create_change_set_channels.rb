class CreateChangeSetChannels < ActiveRecord::Migration
  def self.up
    create_table :change_set_channels do |t|
      t.belongs_to :change_set
      t.belongs_to :room_type
      t.belongs_to :channel
      t.string :type
      t.integer :success_log, :references => :change_set_logs
      t.timestamps
    end
  end

  def self.down
    drop_table :change_set_channels
  end
end
