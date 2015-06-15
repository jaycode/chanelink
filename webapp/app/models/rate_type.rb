class RateType < ActiveRecord::Base
  belongs_to :account
  has_many :room_type_channel_mappings
end