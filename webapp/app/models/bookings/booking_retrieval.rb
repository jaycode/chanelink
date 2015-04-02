# not used for now
class BookingRetrieval < ActiveRecord::Base

  extend Unscoped

  belongs_to :channel
  belongs_to :property

  unscope :property
  
end
