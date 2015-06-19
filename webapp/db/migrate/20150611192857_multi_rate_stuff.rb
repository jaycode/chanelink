class MultiRateStuff < ActiveRecord::Migration
  def self.up
    create_table "rate_types", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.string   "name"
      t.integer  "account_id"
      t.boolean  "deleted", :default => false
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
    add_column :master_rates, :rate_type_id, :integer
    add_column :channel_ctas, :rate_type_id, :integer
    add_column :channel_ctbs, :rate_type_id, :integer
    add_column :channel_ctds, :rate_type_id, :integer
    add_column :channel_min_stays, :rate_type_id, :integer
    add_column :channel_rates, :rate_type_id, :integer
    add_column :channel_stop_sells, :rate_type_id, :integer
    add_column :room_type_master_rate_mappings, :rate_type_id, :integer
    remove_column :room_type_channel_mappings, :agoda_room_type_id
    remove_column :room_type_channel_mappings, :agoda_room_type_name
    remove_column :room_type_channel_mappings, :ctrip_room_type_name
    remove_column :room_type_channel_mappings, :ctrip_room_rate_plan_code
    remove_column :room_type_channel_mappings, :ctrip_room_rate_plan_category

    add_column :inventories, :rate_type_id, :integer
  end

  def self.down
    drop_table "rate_types"
    remove_column :room_type_channel_mappings, :rate_type_id
    remove_column :room_type_master_rate_channel_mappings, :rate_type_id
    remove_column :room_type_channel_mappings, :ota_room_type_id
    remove_column :room_type_channel_mappings, :ota_room_type_name
    remove_column :room_type_channel_mappings, :ota_rate_type_id
    remove_column :room_type_channel_mappings, :ota_rate_type_name
    remove_column :master_rates, :rate_type_id
    remove_column :channel_ctas, :rate_type_id
    remove_column :channel_ctbs, :rate_type_id
    remove_column :channel_ctds, :rate_type_id
    remove_column :channel_min_stays, :rate_type_id
    remove_column :channel_rates, :rate_type_id
    remove_column :channel_stop_sells, :rate_type_id
    remove_column :room_type_master_rate_mappings, :rate_type_id
    add_column :room_type_channel_mappings, :agoda_room_type_id, :string
    add_column :room_type_channel_mappings, :agoda_room_type_name, :string
    add_column :room_type_channel_mappings, :ctrip_room_type_name, :string
    add_column :room_type_channel_mappings, :ctrip_room_rate_plan_code, :string
    add_column :room_type_channel_mappings, :ctrip_room_rate_plan_category, :string

    remove_column :inventories, :rate_type_id
  end
end
