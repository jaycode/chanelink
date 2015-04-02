class AddCurrencyConversionEnabledToProperties < ActiveRecord::Migration
  def self.up
    add_column :properties, :currency_conversion_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :properties, :currency_conversion_enabled
  end
end
