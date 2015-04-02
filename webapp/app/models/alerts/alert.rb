# class representing member's alert
class Alert < ActiveRecord::Base
  #CONSTANT
  DEFAULT_PER_PAGE = 10

  # include this module to provide calling link_to method inside model
  include ActionView::Helpers::UrlHelper

  belongs_to :receiver, :class_name => "Member", :foreign_key => 'receiver_id'
  belongs_to :property
  default_scope lambda {{ :conditions => ["deleted = ?", false] }}

  # scope
  default_scope :order => "created_at desc"
  scope :by_member_and_property, lambda{ |member_id, property_id| {:conditions => ["receiver_id = ? and property_id = ?", member_id, property_id]}}
  scope :by_member_and_property_and_read, lambda{ |member_id, property_id, read| {:conditions => ["receiver_id = ? and property_id = ? and `read` = ?", member_id, property_id, read]}}

  after_create :send_email

  attr_accessor :previous_read

  #this method should be call from instance of Alert subclass or will be raise NotImplemented error
  def to_display
    raise NotImplementedError
  end

  # helper method to enable routing path calling inside model that subclass of this class
  def path_helper
    Rails.application.routes.url_helpers
  end

  # check if it's a admin message (sender and receiver is the same)
  def from_admin?
    if self.sender == self.receiver
      true
    else
      false
    end
  end
  
  def date_display
    DateUtils.date_to_key(self.created_at)
  end

  def send_email
    # do nothing
  end
end