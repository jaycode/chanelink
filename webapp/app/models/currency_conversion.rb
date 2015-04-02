# class representing currency conversion setting/record
class CurrencyConversion < ActiveRecord::Base

  belongs_to :property_channel
  belongs_to :to_currency, :class_name => 'Currency', :foreign_key => 'to_currency_id'

  scope :property_channel_ids, lambda{ |property_channel_ids| {:conditions => ["property_channel_id IN (?)", property_channel_ids]}}

  validates :multiplier, :presence => true, :numericality => {:greater_than => 0, :less_than => 10000000000000}
  validates :to_currency, :presence => true
  validates :property_channel, :presence => true

  def convert_to_base_currency(amount)
    (amount * 1.0)/self.multiplier
  end

end
