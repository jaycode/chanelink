class CreateCurrencyConversions < ActiveRecord::Migration
  def self.up
    create_table :currency_conversions do |t|
      t.belongs_to :property_channel
      t.column :to_currency_id, :integer, :null => true, :references => :currencies
      t.decimal :multiplier, :precision => 8, :scale => 2
      t.timestamps
    end
  end

  def self.down
    drop_table :currency_conversions
  end
end
