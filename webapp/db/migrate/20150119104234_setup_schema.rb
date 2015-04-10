class SetupSchema < ActiveRecord::Migration
  def self.up
  	  create_table "accounts", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "name"
	    t.text     "address"
	    t.string   "telephone"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.boolean  "approved",      :default => false
	    t.string   "contact_name"
	    t.string   "contact_email"
	    t.string   "agoda_api_key"
	    t.boolean  "disabled",      :default => false
	    t.boolean  "deleted",       :default => false
	  end

	  add_index "accounts", ["id"], :name => "index_accounts_on_id", :unique => true

	  create_table "alerts", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "receiver_id",                    :null => false
	    t.integer  "data_id"
	    t.string   "type"
	    t.boolean  "read",        :default => false
	    t.boolean  "deleted",     :default => false
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.string   "message"
	    t.integer  "property_id"
	  end

	  create_table "booking_retrievals", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.text     "request_xml",   :limit => 2147483647
	    t.text     "response_xml",  :limit => 2147483647
	    t.string   "response_code"
	    t.integer  "channel_id"
	    t.integer  "property_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "booking_statuses", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "name"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "bookingcom_booking_datas", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "bookings_id"
	    t.decimal  "total_commission_amount",       :precision => 10, :scale => 0
	    t.string   "currency_code"
	    t.string   "customer_address"
	    t.string   "customer_cc_cvc"
	    t.string   "customer_cc_expiration_date"
	    t.string   "customer_cc_name"
	    t.string   "customer_cc_number"
	    t.string   "customer_cc_type"
	    t.string   "customer_city"
	    t.string   "customer_company"
	    t.string   "customer_countrycode"
	    t.string   "customer_dc_issue_number"
	    t.string   "customer_dc_start_date"
	    t.string   "customer_email"
	    t.string   "customer_first_name"
	    t.string   "customer_last_name"
	    t.string   "customer_remarks"
	    t.string   "customer_telephone"
	    t.string   "customer_zip"
	    t.string   "reservation_commission_amount"
	    t.string   "reservation_currencycode"
	    t.string   "reservation_extra_info"
	    t.string   "reservation_facilities"
	    t.string   "reservation_info"
	    t.string   "reservation_max_children"
	    t.string   "reservation_meal_plan"
	    t.string   "reservation_name"
	    t.string   "reservation_numberofguests"
	    t.string   "reservation_price"
	    t.string   "reservation_remarks"
	    t.string   "reservation_smoking"
	    t.string   "reservation_totalprice"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "bookings", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "type"
	    t.integer  "channel_id"
	    t.integer  "property_id"
	    t.integer  "room_type_id"
	    t.integer  "pool_id"
	    t.string   "guest_name"
	    t.datetime "date_start"
	    t.datetime "date_end"
	    t.datetime "booking_date"
	    t.integer  "total_rooms"
	    t.decimal  "amount",                         :precision => 10, :scale => 0
	    t.string   "agoda_booking_id"
	    t.string   "expedia_booking_id"
	    t.string   "bookingcom_booking_id"
	    t.string   "bookingcom_status"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.string   "status"
	    t.text     "booking_xml"
	    t.string   "expedia_confirm_number"
	    t.boolean  "expedia_confirmed",                                             :default => false
	    t.integer  "booking_status_id"
	    t.text     "bookingcom_room_xml"
	    t.string   "bookingcom_room_reservation_id"
	    t.boolean  "bookingcom_confirmed",                                          :default => false
	    t.string   "uuid"
	    t.string   "encrypted_cc_cvc"
	    t.string   "encrypted_cc_expiration_date"
	    t.string   "encrypted_cc_name"
	    t.string   "encrypted_cc_number"
	    t.string   "encrypted_cc_type"
	    t.string   "gta_travel_booking_id"
	    t.string   "orbitz_booking_id"
	  end

	  create_table "change_set_channel_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "change_set_channel_id"
	    t.text     "request_xml",           :limit => 2147483647
	    t.text     "response_xml",          :limit => 2147483647
	    t.string   "response_code"
	    t.boolean  "success",                                     :default => false
	    t.integer  "attempt"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.integer  "fragment_id"
	  end

	  create_table "change_set_channels", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "change_set_id"
	    t.integer  "room_type_id"
	    t.integer  "channel_id"
	    t.string   "type"
	    t.integer  "success_log"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "change_sets", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "type"
	    t.integer  "room_type_channel_mapping_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channel_cta_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "channel_cta_id"
	    t.boolean  "cta"
	    t.integer  "change_set_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channel_ctas", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.datetime "date"
	    t.integer  "channel_id"
	    t.integer  "room_type_id"
	    t.integer  "property_id"
	    t.integer  "pool_id"
	    t.boolean  "cta"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channel_ctbs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.datetime "date"
	    t.integer  "channel_id"
	    t.integer  "room_type_id"
	    t.integer  "property_id"
	    t.integer  "pool_id"
	    t.boolean  "ctb"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channel_ctd_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "channel_ctd_id"
	    t.boolean  "ctd"
	    t.integer  "change_set_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channel_ctds", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.datetime "date"
	    t.integer  "channel_id"
	    t.integer  "room_type_id"
	    t.integer  "property_id"
	    t.integer  "pool_id"
	    t.boolean  "ctd"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channel_min_stay_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "channel_min_stay_id"
	    t.integer  "min_stay"
	    t.integer  "change_set_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channel_min_stays", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.datetime "date"
	    t.integer  "channel_id"
	    t.integer  "room_type_id"
	    t.integer  "property_id"
	    t.integer  "pool_id"
	    t.integer  "min_stay"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channel_rate_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "channel_rate_id"
	    t.decimal  "amount",          :precision => 30, :scale => 20
	    t.integer  "change_set_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channel_rates", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.datetime "date"
	    t.integer  "channel_id"
	    t.integer  "room_type_id"
	    t.integer  "property_id"
	    t.integer  "pool_id"
	    t.decimal  "amount",       :precision => 30, :scale => 20
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channel_stop_sell_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "channel_stop_sell_id"
	    t.boolean  "stop_sell"
	    t.integer  "change_set_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channel_stop_sells", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.datetime "date"
	    t.integer  "channel_id"
	    t.integer  "room_type_id"
	    t.integer  "property_id"
	    t.integer  "pool_id"
	    t.boolean  "stop_sell"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "channels", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "name"
	    t.string   "type"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "configurations", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "days_to_keep_cc_info"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "countries", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "code"
	    t.string   "name"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  add_index "countries", ["id"], :name => "index_countries_on_id", :unique => true

	  create_table "currencies", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "code"
	    t.string   "name"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  add_index "currencies", ["id"], :name => "index_currencies_on_id", :unique => true

	  create_table "currency_conversions", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "property_channel_id"
	    t.integer  "to_currency_id"
	    t.decimal  "multiplier",          :precision => 30, :scale => 20
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "delayed_jobs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "priority",   :default => 0
	    t.integer  "attempts",   :default => 0
	    t.text     "handler"
	    t.text     "last_error"
	    t.datetime "run_at"
	    t.datetime "locked_at"
	    t.datetime "failed_at"
	    t.string   "locked_by"
	    t.string   "queue"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

	  create_table "gta_travel_channel_cta_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "gta_travel_channel_cta_id"
	    t.boolean  "cta"
	    t.integer  "change_set_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "gta_travel_channel_ctas", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.datetime "date"
	    t.integer  "channel_id"
	    t.integer  "property_id"
	    t.integer  "pool_id"
	    t.boolean  "cta"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "gta_travel_channel_ctb_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "gta_travel_channel_ctb_id"
	    t.boolean  "ctb"
	    t.integer  "change_set_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "gta_travel_channel_ctbs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.datetime "date"
	    t.integer  "channel_id"
	    t.integer  "property_id"
	    t.integer  "pool_id"
	    t.boolean  "ctb"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "inventories", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.datetime "date"
	    t.integer  "room_type_id"
	    t.integer  "property_id"
	    t.integer  "pool_id"
	    t.integer  "total_rooms"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "inventory_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "inventory_id"
	    t.integer  "booking_id"
	    t.string   "type"
	    t.integer  "total_rooms"
	    t.integer  "change_set_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "master_rate_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "master_rate_id"
	    t.decimal  "amount",         :precision => 30, :scale => 20
	    t.integer  "change_set_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "master_rate_new_room_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "master_rate_id"
	    t.decimal  "amount",         :precision => 30, :scale => 2
	    t.integer  "change_set_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "master_rates", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.datetime "date"
	    t.integer  "room_type_id"
	    t.integer  "property_id"
	    t.integer  "pool_id"
	    t.decimal  "amount",       :precision => 30, :scale => 20
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "member_logins", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "member_id"
	    t.boolean  "success"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "member_property_accesses", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "member_id"
	    t.integer  "property_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "member_roles", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "type"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "members", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "email"
	    t.text     "name"
	    t.string   "hashed_password"
	    t.string   "salt"
	    t.integer  "role_id"
	    t.integer  "account_id"
	    t.boolean  "prompt_password_change", :default => true
	    t.boolean  "disabled",               :default => false
	    t.boolean  "deleted",                :default => false
	    t.boolean  "master",                 :default => false
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  add_index "members", ["id"], :name => "index_members_on_id", :unique => true

	  create_table "pools", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "name"
	    t.integer  "property_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.boolean  "deleted",     :default => false
	  end

	  create_table "properties", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "name"
	    t.text     "address"
	    t.string   "city"
	    t.string   "state"
	    t.string   "postcode"
	    t.decimal  "minimum_room_rate",           :precision => 30, :scale => 20
	    t.integer  "country_id"
	    t.integer  "account_id"
	    t.string   "agoda_hotel_id"
	    t.string   "expedia_hotel_id"
	    t.string   "expedia_username"
	    t.string   "expedia_password"
	    t.string   "bookingcom_hotel_id"
	    t.string   "bookingcom_username"
	    t.string   "bookingcom_password"
	    t.boolean  "approved",                                                    :default => false
	    t.integer  "currency_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.boolean  "rejected",                                                    :default => false
	    t.boolean  "deleted",                                                     :default => false
	    t.boolean  "currency_conversion_enabled",                                 :default => false
	  end

	  add_index "properties", ["id"], :name => "index_properties_on_id", :unique => true

	  create_table "property_channels", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "property_id"
	    t.integer  "channel_id"
	    t.integer  "pool_id"
	    t.decimal  "rate_conversion_multiplier",           :precision => 30, :scale => 20
	    t.string   "agoda_username"
	    t.string   "agoda_password"
	    t.string   "agoda_currency"
	    t.string   "expedia_reservation_email_address"
	    t.string   "expedia_modification_email_address"
	    t.string   "expedia_cancellation_email_address"
	    t.string   "expedia_currency"
	    t.string   "bookingcom_username"
	    t.string   "bookingcom_password"
	    t.string   "bookingcom_reservation_email_address"
	    t.boolean  "disabled",                                                             :default => true
	    t.boolean  "approved",                                                             :default => false
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.string   "tiketcom_hotel_key"
	    t.boolean  "deleted",                                                              :default => false
	    t.string   "gta_travel_property_id"
	    t.string   "gta_travel_contract_id"
	    t.string   "gta_travel_username"
	    t.string   "gta_travel_password"
	    t.string   "ctrip_hotel_code"
	    t.string   "ctrip_room_type_name"
	    t.string   "ctrip_room_rate_plan_category"
	    t.string   "ctrip_room_rate_plan_code"
	    t.string   "orbitz_hotel_code"
	    t.string   "orbitz_chain_code"
	  end

	  create_table "room_type_channel_mappings", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "room_type_id"
	    t.integer  "channel_id"
	    t.string   "agoda_room_type_id"
	    t.string   "agoda_room_type_name"
	    t.decimal  "agoda_single_rate_modifier",           :precision => 30, :scale => 20
	    t.decimal  "agoda_double_rate_modifier",           :precision => 30, :scale => 20
	    t.decimal  "agoda_full_rate_modifier",             :precision => 30, :scale => 20
	    t.decimal  "agoda_single_rate_multiplier",         :precision => 30, :scale => 20
	    t.decimal  "agoda_double_rate_multiplier",         :precision => 30, :scale => 20
	    t.decimal  "agoda_full_rate_multiplier",           :precision => 30, :scale => 20
	    t.boolean  "agoda_breakfast_inclusion",                                            :default => false
	    t.integer  "agoda_release_period"
	    t.decimal  "agoda_extra_bed_rate",                 :precision => 30, :scale => 20
	    t.string   "expedia_room_type_id"
	    t.string   "expedia_room_type_name"
	    t.string   "expedia_rate_plan_id"
	    t.decimal  "expedia_rate_conversion_multiplier",   :precision => 30, :scale => 20
	    t.string   "bookingcom_room_type_id"
	    t.string   "bookingcom_room_type_name"
	    t.string   "bookingcom_rate_plan_id"
	    t.decimal  "bookingcom_single_rate_discount",      :precision => 30, :scale => 20
	    t.decimal  "new_rate",                             :precision => 30, :scale => 20
	    t.string   "rate_configuration"
	    t.boolean  "initial_rate_pushed",                                                  :default => false
	    t.boolean  "disabled",                                                             :default => false
	    t.boolean  "deleted",                                                              :default => false
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.string   "gta_travel_room_type_id"
	    t.string   "gta_travel_room_type_name"
	    t.string   "gta_travel_rate_type"
	    t.string   "gta_travel_rate_gross"
	    t.string   "gta_travel_rate_margin"
	    t.string   "gta_travel_contract_id"
	    t.decimal  "gta_travel_single_rate_multiplier",    :precision => 8,  :scale => 2
	    t.decimal  "gta_travel_double_rate_multiplier",    :precision => 8,  :scale => 2
	    t.decimal  "gta_travel_triple_rate_multiplier",    :precision => 8,  :scale => 2
	    t.boolean  "gta_travel_full_period",                                               :default => false
	    t.string   "gta_travel_rate_plan_id"
	    t.decimal  "gta_travel_quadruple_rate_multiplier", :precision => 30, :scale => 20
	    t.integer  "gta_travel_rate_basis",                                                :default => 0
	    t.integer  "gta_travel_max_occupancy",                                             :default => 0
	    t.string   "orbitz_room_type_id"
	    t.string   "orbitz_room_type_name"
	    t.decimal  "orbitz_single_rate_multiplier",        :precision => 30, :scale => 20
	    t.decimal  "orbitz_double_rate_multiplier",        :precision => 30, :scale => 20
	    t.string   "orbitz_rate_plan_id"
	    t.decimal  "orbitz_additional_guest_amount",       :precision => 30, :scale => 20
	    t.decimal  "orbitz_triple_rate_multiplier",        :precision => 30, :scale => 20
	    t.decimal  "orbitz_quad_rate_multiplier",          :precision => 30, :scale => 20
	    t.string   "ctrip_room_type_name"
	    t.string   "ctrip_room_rate_plan_category"
	    t.string   "ctrip_room_rate_plan_code"
	  end

	  create_table "room_type_inventory_links", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "property_id"
	    t.integer  "room_type_from_id",                    :null => false
	    t.integer  "room_type_to_id",                      :null => false
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.boolean  "deleted",           :default => false
	  end

	  create_table "room_type_master_rate_channel_mappings", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "room_type_master_rate_mapping_id"
	    t.integer  "room_type_id"
	    t.integer  "channel_id"
	    t.string   "method"
	    t.decimal  "percentage",                       :precision => 30, :scale => 20
	    t.decimal  "value",                            :precision => 30, :scale => 20
	    t.boolean  "disabled",                                                         :default => false
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.boolean  "deleted",                                                          :default => false
	  end

	  create_table "room_type_master_rate_mappings", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "pool_id"
	    t.integer  "room_type_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.boolean  "deleted",      :default => false
	  end

	  create_table "room_types", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "name"
	    t.decimal  "rack_rate",    :precision => 30, :scale => 20
	    t.decimal  "minimum_rate", :precision => 30, :scale => 20
	    t.integer  "minimum_stay"
	    t.integer  "property_id"
	    t.boolean  "deleted",                                      :default => false
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "sessions", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "session_id", :null => false
	    t.text     "data"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
	  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

	  create_table "user_logins", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "user_id"
	    t.boolean  "success"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "user_property_accesses", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.integer  "user_id"
	    t.integer  "property_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	  end

	  create_table "users", :force => true, :options => "ENGINE=MyISAM" do |t|
	    t.string   "name"
	    t.string   "email"
	    t.string   "email_validation_key"
	    t.string   "hashed_password"
	    t.string   "reset_password_key"
	    t.string   "salt"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.boolean  "prompt_password_change", :default => true
	    t.boolean  "super",                  :default => false
	    t.boolean  "deleted",                :default => false
	  end

	  add_index "users", ["id"], :name => "index_users_on_id", :unique => true
  end

  def self.down
  end
end
