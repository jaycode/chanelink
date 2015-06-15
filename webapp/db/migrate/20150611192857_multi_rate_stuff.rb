class MultiRateStuff < ActiveRecord::Migration
  def self.up
    create_table "rate_types", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.string   "name"
      t.integer  "account_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    # Todo: These two tables need to be joined as one.
    add_column :room_type_channel_mappings, :rate_type_id, :integer
    add_column :room_type_master_rate_channel_mappings, :rate_type_id, :integer
    add_column :room_type_channel_mappings, :ota_room_type_id, :string
    add_column :room_type_channel_mappings, :ota_room_type_name, :string
    add_column :room_type_channel_mappings, :ota_rate_type_id, :string
    add_column :room_type_channel_mappings, :ota_rate_type_name, :string
    remove_column :room_type_channel_mappings, :agoda_room_type_id
    remove_column :room_type_channel_mappings, :agoda_room_type_name
    remove_column :room_type_channel_mappings, :ctrip_room_type_name
    remove_column :room_type_channel_mappings, :ctrip_room_rate_plan_code
    remove_column :room_type_channel_mappings, :ctrip_room_rate_plan_category
  end

  def self.down
    drop_table "rate_type_property_channels"
    drop_table "rate_types"
    remove_column :room_type_channel_mappings, :rate_type_property_channel_id
    remove_column :room_type_master_rate_channel_mappings, :rate_type_property_channel_id
    remove_column :room_type_channel_mappings, :ota_room_type_id
    remove_column :room_type_channel_mappings, :ota_room_type_name
    remove_column :room_type_channel_mappings, :ota_rate_type_id
    remove_column :room_type_channel_mappings, :ota_rate_type_name
    add_column :room_type_channel_mappings, :agoda_room_type_id, :string
    add_column :room_type_channel_mappings, :agoda_room_type_name, :string
    add_column :room_type_channel_mappings, :ctrip_room_type_name, :string
    add_column :room_type_channel_mappings, :ctrip_room_rate_plan_code, :string
    add_column :room_type_channel_mappings, :ctrip_room_rate_plan_category, :string

  end
end
