# represent a customer account
class Account < ActiveRecord::Base

  ADDRESS_MINIMUM_LENGTH = 15
  ADDRESS_MAXIMUM_LENGTH = 200
  TELEPHONE_MINIMUM_LENGTH = 5
  TELEPHONE_MAXIMUM_LENGTH = 25
  NAME_MINIMUM_LENGTH = 3
  NAME_MAXIMUM_LENGTH = 100
  EMAIL_MAXIMUM_LENGTH = 100
  CONTACT_NAME_MINIMUM_LENGTH = 3
  CONTACT_NAME_MAXIMUM_LENGTH = 100
  
  has_many :members
  has_many :properties

  validates :name,
    :length => {:minimum => NAME_MINIMUM_LENGTH, :maximum => NAME_MAXIMUM_LENGTH}

  validates :address,
    :length => {:minimum => ADDRESS_MINIMUM_LENGTH, :maximum => ADDRESS_MAXIMUM_LENGTH}

  validates :telephone,
    :length => {:minimum => TELEPHONE_MINIMUM_LENGTH, :maximum => TELEPHONE_MAXIMUM_LENGTH}

  validates :contact_email,
    :uniqueness => true,
    :length => { :maximum => EMAIL_MAXIMUM_LENGTH },
    :format => { :with => /^[^@][\w.-]+@[\w.-]+[.][a-z]{2,4}$/i}

  validates :contact_name,
    :length => {:minimum => CONTACT_NAME_MINIMUM_LENGTH, :maximum => CONTACT_NAME_MAXIMUM_LENGTH}

  default_scope lambda {{ :conditions => ["deleted = ?", false] }}
  scope :not_approved, lambda { {:conditions => ["approved is false"]} }
  scope :approved, lambda { {:conditions => ["approved is true"]} }

  attr_accessor :enabled

  # list of all account for use in the UI
  def self.select_list
    result = Array.new
    result << [I18n.t('admin.properties.new.label.account_placeholder'), nil]
    Account.order(:name).each do |account|
      result << [account.name, account.id]
    end
    result
  end

  # list of all account for use in the UI, with no empty selection
  def self.select_list_no_empty
    result = Array.new
    Account.order(:name).each do |account|
      result << [account.name, account.id]
    end
    result
  end

  # list of all account where the User has at least access to one of the account's properties
  def self.select_list_check_user_access(user)
    result = Array.new
    Account.order(:name).each do |account|
      if UserPropertyAccess.property_ids(account.property_ids).find_all_by_user_id(user.id).count > 0 or user.super?
        result << [account.name, account.id]
      end
    end
    result
  end

  # equality for account
  def ==(other)
    return self.id == other.id
  end

  # get all super member in this account
  def super_members
    self.members.find_all_by_role_id(MemberRole.super_role.id)
  end

  # get all config member in this account
  def config_members
    self.members.find_all_by_role_id(MemberRole.config_role.id)
  end

  # get all general member in this account
  def general_members
    self.members.find_all_by_role_id(MemberRole.general_role.id)
  end
  
  # get all property ids for his account
  def property_ids
    result = Array.new
    self.properties.each do |p|
      result << p.id
    end
    result
  end

end
