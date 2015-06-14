class MultiRateStuff < ActiveRecord::Migration
  def self.up
    create_table "rate_types", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.string   "name"
      t.integer  "account_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "rate_type_property_channels", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.integer  "property_channel_id"
      t.integer  "rate_type_id"
      t.string   "ota_rate_type_name"
      t.string   "ota_rate_type_id"
      t.string   "settings", :default => ActiveSupport::JSON.encode({})
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    # Todo: These two tables need to be joined as one.
    add_column :room_type_channel_mappings, :rate_type_property_channel_id, :integer
    add_column :room_type_master_rate_channel_mappings, :rate_type_property_channel_id, :integer
  end

  def self.down
    drop_table "rate_type_property_channels"
    drop_table "rate_types"
    remove_column :room_type_channel_mappings, :rate_type_property_channel_id
    remove_column :room_type_master_rate_channel_mappings, :rate_type_property_channel_id
  end
end
