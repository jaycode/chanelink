# represent every member login attempt
class MemberLogin < ActiveRecord::Base

  belongs_to :member

  scope :failed_in_the_last_hour_after_last_update, lambda { |last_update| {:conditions => ["success is false and created_at >= ? and created_at >= ?", (DateTime.now - 1.hour), last_update ]} }
  
end
