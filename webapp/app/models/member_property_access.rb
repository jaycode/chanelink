# a record of a property access to member
class MemberPropertyAccess < ActiveRecord::Base

  scope :member_ids, lambda{ |member_ids| {:conditions => ["member_id IN (?)", member_ids]}}
  
end
