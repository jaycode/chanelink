class CreateRoomTypeChannelMappings < ActiveRecord::Migration
  def self.up
    create_table :room_type_channel_mappings do |t|
      t.belongs_to :room_type
      t.belongs_to :channel
      
      t.string :agoda_room_type_id
      t.string :agoda_room_type_name
      t.decimal :agoda_single_rate_modifier, :precision => 8, :scale => 2
      t.decimal :agoda_double_rate_modifier, :precision => 8, :scale => 2
      t.decimal :agoda_full_rate_modifier, :precision => 8, :scale => 2
      t.decimal :agoda_single_rate_multiplier, :precision => 8, :scale => 2
      t.decimal :agoda_double_rate_multiplier, :precision => 8, :scale => 2
      t.decimal :agoda_full_rate_multiplier, :precision => 8, :scale => 2
      t.boolean :agoda_breakfast_inclusion, :default => false
      t.integer :agoda_release_period
      t.decimal :agoda_extra_bed_rate, :precision => 8, :scale => 2

      t.string :expedia_room_type_id
      t.string :expedia_room_type_name
      t.string :expedia_rate_plan_id
      t.decimal :expedia_rate_conversion_multiplier, :precision => 8, :scale => 2

      t.string :bookingcom_room_type_id
      t.string :bookingcom_room_type_name
      t.string :bookingcom_rate_plan_id
      t.decimal :bookingcom_single_rate_discount, :precision => 8, :scale => 2

      t.decimal :new_rate, :precision => 8, :scale => 2
      t.string :rate_configuration
      t.boolean :initial_rate_pushed, :default => false
      t.boolean :disabled, :default => false
      t.boolean :deleted, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :room_type_channel_mappings
  end
end
