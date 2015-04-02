class IncreasePrecisionToAllv2 < ActiveRecord::Migration
  def self.up
    change_column :properties, :minimum_room_rate, :decimal, :precision => 30, :scale => 20
    change_column :room_types, :rack_rate, :decimal, :precision => 30, :scale => 20
    change_column :room_types, :minimum_rate, :decimal, :precision => 30, :scale => 20
    change_column :property_channels, :rate_conversion_multiplier, :decimal, :precision => 30, :scale => 20

    change_column :room_type_channel_mappings, :agoda_single_rate_modifier, :decimal, :precision => 30, :scale => 20
    change_column :room_type_channel_mappings, :agoda_double_rate_modifier, :decimal, :precision => 30, :scale => 20
    change_column :room_type_channel_mappings, :agoda_full_rate_modifier, :decimal, :precision => 30, :scale => 20
    change_column :room_type_channel_mappings, :agoda_single_rate_multiplier, :decimal, :precision => 30, :scale => 20
    change_column :room_type_channel_mappings, :agoda_double_rate_multiplier, :decimal, :precision => 30, :scale => 20
    change_column :room_type_channel_mappings, :agoda_full_rate_multiplier, :decimal, :precision => 30, :scale => 20
    change_column :room_type_channel_mappings, :agoda_extra_bed_rate, :decimal, :precision => 30, :scale => 20

    change_column :room_type_channel_mappings, :expedia_rate_conversion_multiplier, :decimal, :precision => 30, :scale => 20
    change_column :room_type_channel_mappings, :bookingcom_single_rate_discount, :decimal, :precision => 30, :scale => 20
    change_column :room_type_channel_mappings, :new_rate, :decimal, :precision => 30, :scale => 20

    change_column :master_rates, :amount, :decimal, :precision => 30, :scale => 20
    change_column :channel_rates, :amount, :decimal, :precision => 30, :scale => 20
    change_column :room_type_master_rate_channel_mappings, :percentage, :decimal, :precision => 30, :scale => 20
    change_column :room_type_master_rate_channel_mappings, :value, :decimal, :precision => 30, :scale => 20

    change_column :master_rate_logs, :amount, :decimal, :precision => 30, :scale => 20
    change_column :channel_rate_logs, :amount, :decimal, :precision => 30, :scale => 20
    change_column :currency_conversions, :multiplier, :decimal, :precision => 30, :scale => 20
  end

  def self.down
  end
end
