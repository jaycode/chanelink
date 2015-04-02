class CreateMasterRateNewRoomLogs < ActiveRecord::Migration
  def self.up
    create_table :master_rate_new_room_logs do |t|
      t.belongs_to :master_rate
      t.decimal :amount, :precision => 8, :scale => 2
      t.belongs_to :change_set
      t.timestamps
    end
  end

  def self.down
    drop_table :master_rate_new_room_logs
  end
end
