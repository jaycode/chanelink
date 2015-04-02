# represent backoffice user property access
class UserPropertyAccess < ActiveRecord::Base

  scope :property_ids, lambda{ |property_ids| {:conditions => ["property_id IN (?)", property_ids]}}
  
end
