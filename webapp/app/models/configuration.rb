class Configuration < ActiveRecord::Base

  validates :days_to_keep_cc_info, :numericality => {:only_integer => true, :greater_than => 0, :less_than => 30}
  
end
