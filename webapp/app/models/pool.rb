# represent a pool
class Pool < ActiveRecord::Base

  extend Unscoped

  belongs_to :property
  has_many :channels, :class_name => 'PropertyChannel', :foreign_key => 'pool_id'
  has_many :master_rate_mappings, :class_name => 'RoomTypeMasterRateMapping', :foreign_key => 'pool_id'
  has_many :inventories

  default_scope lambda {{ :conditions => ["deleted = ?", false] }}

  unscope :property

  NAME_MINIMUM_LENGTH = 3
  NAME_MAXIMUM_LENGTH = 25

  DEFAULT_NAME = 'Default'

  validates :name,
    :uniqueness => {:case_sensitive => false, :scope => :property_id},
    :length => {:minimum => NAME_MINIMUM_LENGTH, :maximum => NAME_MAXIMUM_LENGTH}

  attr_accessor :assigned_channels

  # equality for pool
  def ==(other)
    return self.id == other.id
  end

  # all channel ids under this pool
  def channel_ids_list
    self.channels.collect &:channel_id
  end

  # create default pool
  def self.generate_default_pool
    Pool.new(:name => DEFAULT_NAME)
  end

  # pool list with all option
  def self.pool_list(property)
    result = Array.new
    result << [I18n.t("reports.checkin.pools.all"), '']
    property.pools.each do |pool|
      result << [pool.name, pool.id]
    end
    result
  end

  # pool list without all option
  def self.pool_list_without_all(property)
    result = Array.new
    property.pools.each do |pool|
      result << [pool.name, pool.id]
    end
    result
  end

  # pool list for bulk update
  def self.pool_list_for_bulk_update(property)
    result = Array.new
    result << [I18n.t("reports.checkin.pools.all"), 'all']
    property.pools.each do |pool|
      result << [pool.name, pool.id]
    end
    result
  end

  # pool list with prompt
  def self.pool_list_with_prompt(property)
    result = Array.new
    result << [I18n.t('pools.placeholder'), nil]
    property.pools.each do |pool|
      result << [pool.name, pool.id]
    end
    result
  end

  # pool list with channel grouping
  def self.list_channel_by_pool_group(property, exlcude_pool = nil)
    result = Array.new
    property.pools.each do |pool|
      if !pool.channels.blank? and (!exlcude_pool or pool != exlcude_pool)
        channels = Array.new

        # grouped by channel
        pool.channels.each do |pc|
          channels << [pc.channel.name, pc.channel.id]
        end
        result << [pool.name, channels]
      end
    end

    result
  end

  # not used
  def self.ids_to_list(ids)
    result = Array.new
    unless ids.blank?
      ids.each do |id|
        channel = Channel.find(id)
        result << [channel.name, channel.id]
      end
    end
    result
  end

  # check if this pool has no inventories record
  def zero_inventories?
    if self.inventories.blank?
      return true
    else
      # if record exist, check whether all the record is 0 or not
      self.inventories.each do |inv|
        return false if inv.total_rooms > 0 and inv.date >= DateTime.now.in_time_zone.beginning_of_day
      end
      return true
    end
  end

  # check if all master rate rooms has been added
  def all_master_rate_rooms_added?
    room_type_ids = self.master_rate_mappings.collect &:room_type_id
    self.property.room_types.each do |rt|
     return false if !room_type_ids.include?(rt.id)
    end
    return true
  end

  # check whether the pool has channel
  def has_channel?
    if PropertyChannel.find_by_pool_id(self.id).blank?
      false
    else
      true
    end
  end

end
