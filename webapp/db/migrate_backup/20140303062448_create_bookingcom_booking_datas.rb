class CreateBookingcomBookingDatas < ActiveRecord::Migration
  def self.up
    create_table :bookingcom_booking_datas do |t|
      t.belongs_to :bookings
      t.decimal :total_commission_amount
      t.string :currency_code
      t.string :customer_address
      t.string :customer_cc_cvc
      t.string :customer_cc_expiration_date
      t.string :customer_cc_name
      t.string :customer_cc_number
      t.string :customer_cc_type
      t.string :customer_city
      t.string :customer_company
      t.string :customer_countrycode
      t.string :customer_dc_issue_number
      t.string :customer_dc_start_date
      t.string :customer_email
      t.string :customer_first_name
      t.string :customer_last_name
      t.string :customer_remarks
      t.string :customer_telephone
      t.string :customer_zip

      t.string :reservation_commission_amount
      t.string :reservation_currencycode
      t.string :reservation_extra_info
      t.string :reservation_facilities
      
      t.string :reservation_info
      t.string :reservation_max_children
      t.string :reservation_meal_plan
      t.string :reservation_name
      t.string :reservation_numberofguests
      t.string :reservation_price
      t.string :reservation_remarks
      t.string :reservation_smoking
      t.string :reservation_totalprice
      
      t.timestamps
    end
  end

  def self.down
    drop_table :bookingcom_booking_datas
  end
end
