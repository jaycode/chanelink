class IncreasePrecisionRoundTwo < ActiveRecord::Migration
  def self.up
    change_column :master_rate_new_room_logs, :amount, :decimal, :precision => 30, :scale => 2
  end

  def self.down
  end
end
