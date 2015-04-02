class CreateMasterRates < ActiveRecord::Migration
  def self.up
    create_table :master_rates do |t|
      t.datetime :date
      t.belongs_to :room_type
      t.belongs_to :property
      t.belongs_to :pool
      t.decimal :amount, :precision => 8, :scale => 2

      t.timestamps
    end
  end

  def self.down
    drop_table :master_rates
  end
end
