# super class for all channel/OTA bookings
class Booking < ActiveRecord::Base
  STATUS_BOOK = 'BOOK'
  STATUS_CANCEL = 'CANCEL'
  STATUS_MODIFY = 'MODIFY'

  extend Unscoped
  
  belongs_to :channel
  belongs_to :property
  belongs_to :room_type
  belongs_to :pool
  belongs_to :booking_status

  unscope :property, :room_type, :pool

  scope :date_start_between, lambda {|start_period, end_period| {:conditions => ["date_start >= ? and date_start <= ?", start_period, end_period]}}
  scope :booking_date_between, lambda {|start_period, end_period| {:conditions => ["booking_date >= ? and booking_date <= ?", start_period, end_period]}}
  scope :created_at_between, lambda {|start_period, end_period| {:conditions => ["created_at >= ? and created_at <= ?", start_period, end_period]}}
  scope :new_only, lambda { {:conditions => ["booking_status_id = ?", BookingStatus.new_type.id]} }

  after_create :generate_uuid

  # difference between booking date and stay date
  def lead_time
    (self.date_start.to_date - self.booking_date.to_date).to_i
  end

  # calculate length of stay in days
  def length_of_stay
    (self.date_end.to_date - self.date_start.to_date).to_i - 1
  end

  def generate_uuid
    if self.uuid.blank?
      self.uuid = SecureRandom.hex(10)
      self.save
    end
  end

  def clean_cc_info
    self.update_attributes(:cc_cvc => nil, :cc_expiration_date => nil, :cc_name => nil, :cc_number => nil, :cc_type => nil)
  end

  def amount_in_base_currency
    result = self.amount
    pc = PropertyChannel.find_by_channel_id_and_property_id(self.channel.id, self.property.id)
    if !pc.blank? and !pc.currency_conversion.blank?
      result = pc.currency_conversion.convert_to_base_currency(self.amount)
    end
    result
  end
  
end