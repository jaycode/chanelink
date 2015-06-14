class RateType < ActiveRecord::Base
  belongs_to :account
  has_many :rate_type_property_channels
end