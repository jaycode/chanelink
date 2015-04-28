# represent a property
class Property < ActiveRecord::Base

  extend Unscoped
  include HasSettings

  ADDRESS_MINIMUM_LENGTH = 15
  ADDRESS_MAXIMUM_LENGTH = 200
  CITY_MINIMUM_LENGTH = 3
  CITY_MAXIMUM_LENGTH = 50
  STATE_MINIMUM_LENGTH = 3
  STATE_MAXIMUM_LENGTH = 50
  POSTCODE_MINIMUM_LENGTH = 3
  POSTCODE_MAXIMUM_LENGTH = 50
  NAME_MINIMUM_LENGTH = 3
  NAME_MAXIMUM_LENGTH = 100

  belongs_to :account
  belongs_to :country
  belongs_to :currency
  has_many :room_types
  has_many :pools
  has_many :channels, :class_name => 'PropertyChannel', :foreign_key => 'property_id'
  has_many :inventories
  has_many :rates
  has_many :bookings

  unscope :account

  default_scope lambda {{ :conditions => ["deleted = ?", false] }}

  validates :name,
    :length => {:minimum => NAME_MINIMUM_LENGTH, :maximum => NAME_MAXIMUM_LENGTH},
    :presence => true

  validates :address,
    :length => {:minimum => ADDRESS_MINIMUM_LENGTH, :maximum => ADDRESS_MAXIMUM_LENGTH}

  validates :city,
    :length => {:minimum => CITY_MINIMUM_LENGTH, :maximum => CITY_MAXIMUM_LENGTH}

  validates :state,
    :length => {:minimum => STATE_MINIMUM_LENGTH, :maximum => STATE_MAXIMUM_LENGTH}

  validates :postcode,
    :length => {:minimum => POSTCODE_MINIMUM_LENGTH, :maximum => POSTCODE_MAXIMUM_LENGTH},
    :numericality => {:only_integer => true}

  validates :minimum_room_rate, :presence => true, :numericality => {:greater_than => 0, :less_than => 10000000000000}

  validates :account, :presence => true

  validates :country, :presence => true

  validate :minimum_room_rate_must_be_less_than_lowest

  scope :not_approved, lambda { {:conditions => ["approved is false and rejected is false"]} }
  scope :not_rejected, lambda { {:conditions => ["approved is false and rejected is true"]} }
  scope :rejected, lambda { {:conditions => ["rejected is true"]} }

  scope :active_only, lambda { {:conditions => ["approved = ? and deleted = ?", true, false]} }

  after_create :create_default_pool

  after_initialize :setup_default_settings

  def setup_default_settings
    klasses = Channel.descendants_without_loading
    klasses.each do |klass|
      # Todo: If channels are not kept as model, this is no longer needed.
      channel = klass.first
      unless channel.nil?
        self.update_empty_settings(channel.default_settings)
      end
    end
  end

  # make sure room type minimum is less than
  def minimum_room_rate_must_be_less_than_lowest
    if !self.room_types.blank?
      lowest = 0
      # find the lowest minimum rate
      self.room_types.each do |rt|
        if !rt.minimum_rate.blank?
          if rt.minimum_rate < lowest or lowest == 0
            lowest = rt.minimum_rate
          end
        end
      end
      if lowest > 0 and self.minimum_room_rate > lowest
        errors.add(:minimum_room_rate, I18n.t('properties.validate.minimum_room_rate_must_be_less_than_lowest', :lowest => lowest))
      end
    end
  end

  # return all room type ids
  def room_type_ids
    room_type_ids = Array.new
    self.room_types.each do |rt|
      room_type_ids << rt.id
    end
    room_type_ids
  end

  # return channel ids scoped to a pool
  def channel_ids_by_pool(pool)
    channel_ids = Array.new
    self.channels.each do |pc|
      channel_ids << pc.channel_id if pc.pool_id = pool.id
    end
    channel_ids
  end

  # all room type mapping scoped to a pool
  def mapped_room_types_to_pool(pool)
    room_types = Array.new
    channel_ids = channel_ids_by_pool(pool)
    # go through each room type and check whether it has mapping
    self.room_types.each do |rt|
      unless RoomTypeChannelMapping.channel_ids(channel_ids).where(:room_type_id => rt.id).blank?
        room_types << rt
      end
    end
    room_types
  end

  # find all room types not availability linked
  def rooms_not_inventory_linked
    room_types = Array.new
    self.room_types.each do |rt|
      if RoomTypeInventoryLink.find_by_room_type_from_id(rt.id).blank?
        room_types << rt
      end
    end
    room_types
  end

  # return all members that has access to this property
  def members
    result = Array.new
    self.account.members.each do |member|
      if member.super_member? or !MemberPropertyAccess.find_by_member_id_and_property_id(member.id, self.id).blank?
        result << member
      end
    end
    result
  end

  # check if property has only one pool
  def single_pool?
    self.pools.size == 1 ? true : false
  end

  # check if currency conversion disabled
  def currency_conversion_disabled?
    !self.currency_conversion_enabled?
  end

  # return all property
  def self.property_list
    result = Array.new
    Property.all.each do |pr|
      result << ["#{pr.name} - #{pr.id}", pr.id]
    end
    result
  end

  # check if property is active
  def active?
    if self.account.deleted? or self.account.disabled?
      false
    elsif self.deleted? or self.rejected?
      false
    else
      true
    end
  end

  # equality for property
  def ==(other)
    return self.id == other.id
  end
  
  private

  # create default pool for this property
  def create_default_pool
    default_pool = Pool.generate_default_pool
    self.pools << default_pool
    default_pool.save
  end

end
