# represent a room type record
class RoomType < ActiveRecord::Base

  extend Unscoped

  belongs_to :property
  has_many :inventories

  unscope :property

  default_scope lambda {{ :conditions => ["deleted = ?", false] }}

  NAME_MINIMUM_LENGTH = 3
  NAME_MAXIMUM_LENGTH = 100

  validates :name, :presence => true,
    :length => {:minimum => NAME_MINIMUM_LENGTH, :maximum => NAME_MAXIMUM_LENGTH},
    :uniqueness => {:case_sensitive => false, :scope => :property_id}
  
  validates :rack_rate, :presence => true, :numericality => {:greater_than => 0, :less_than => 10000000000000}

  validates :minimum_stay, :allow_nil => true, :numericality => {:greater_than => 0, :less_than => 10000000000000}

  validate :rack_rate_must_be_over_minimum

  validate :min_rate_must_be_over_minimum

  # make sure ract rate is greater than minimum
  def rack_rate_must_be_over_minimum
    if !rack_rate.blank? and rack_rate < self.final_minimum_rate
      errors.add(:rack_rate, I18n.t('room_types.validate.rack_rate_must_be_over_minimum', :minimum => self.final_minimum_rate))
    end
       
  end

  # check min rate must be greater than property minimum
  def min_rate_must_be_over_minimum
    if !minimum_rate.blank? and minimum_rate < self.property.minimum_room_rate
      errors.add(:minimum_rate, I18n.t('room_types.validate.minimum_rate_must_be_over_minimum', :minimum => self.property.minimum_room_rate))
    end
  end

  # check if room type mapping exist to a channel
  def has_active_mapping_to_channel?(channel)
    rtcm = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(self.id, channel.id)
    if rtcm.blank?
      false
    else
      true
    end
  end

  # check if master rate mapping exist to a channel and pool
  def has_master_rate_mapping_to_channel?(channel, pool)
    unless RoomTypeMasterRateChannelMapping.pool_id(pool.id).find_by_room_type_id_and_channel_id(self.id, channel.id).blank?
      true
    else
      false
    end
  end

  # check if master rate mapping exist scoped to a pool
  def has_master_rate_mapping?(pool)
    unless RoomTypeMasterRateMapping.find_by_pool_id_and_room_type_id(pool.id, self.id).blank?
      true
    else
      false
    end
  end

  # equality for room type
  def ==(other)
    return self.id == other.id
  end

  # whether this room type is linked to other room type inventory
  def is_inventory_linked?
    if RoomTypeInventoryLink.find_by_room_type_from_id(self.id).blank?
      false
    else
      true
    end
  end

  # whether this room type is source inventory for other room type
  def is_inventory_feeder?
    if RoomTypeInventoryLink.find_by_room_type_to_id(self.id).blank?
      false
    else
      true
    end
  end

  # whether this room type is relying to other room type for availability
  def linked_room_type
    if self.is_inventory_linked?
      RoomTypeInventoryLink.find_by_room_type_from_id(self.id).room_type_to
    end
  end

  # all room types that sourced inventory from this room type
  def consumer_room_types
    result = Array.new
    if self.is_inventory_feeder?
      RoomTypeInventoryLink.find_all_by_room_type_to_id(self.id).each do |rtt|
        result << RoomType.find(rtt.room_type_from_id)
      end
    end
    result
  end

  # get inventory considering into account whether this room is linked or not
  def calculated_inventory(date, pool, flash, rate_type)
    result = 0
    if self.is_inventory_linked?
      linked = linked_room_type
      inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_rate_type_id(
        date, self.property.id, pool.id, linked.id, rate_type.id)
      result = inv.total_rooms unless inv.blank?
    else
      # if flash inventory exist, means previous save was failed
      if flash[:inventory] and flash[:inventory][self.id.to_s] and flash[:inventory][self.id.to_s][rate_type.id.to_s]
        result = flash[:inventory][self.id.to_s][rate_type.id.to_s][DateUtils.date_to_key(date)]
      else
        inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_rate_type_id(
          date, self.property.id, pool.id, self.id, rate_type.id)
        result = inv.total_rooms unless inv.blank?
      end
    end
    result
  end

  # clean up all links that was made to this room type
  def clean_up
    if self.deleted?
      # clean room type mapping
      RoomTypeChannelMapping.find_all_by_room_type_id(self.id).each do |rtcm|
        rtcm.update_attribute(:deleted, true)
      end
      # clean master rate mapping
      RoomTypeMasterRateMapping.find_all_by_room_type_id(self.id).each do |rtmr|
        RoomTypeMasterRateChannelMapping.find_all_by_room_type_master_rate_mapping_id(rtmr.id).each do |rtc|
          rtc.update_attribute(:deleted, true)
        end
        rtmr.update_attribute(:deleted, true)
      end
      # clean availability link from
      RoomTypeInventoryLink.find_all_by_room_type_from_id(self.id).each do |rml|
        rml.update_attribute(:deleted, true)
      end
      # clean availability link to
      RoomTypeInventoryLink.find_all_by_room_type_to_id(self.id).each do |rml|
        rml.update_attribute(:deleted, true)
      end
    end
  end

  # if rack rate smaller than minimum of property then take the property ones
  def basic_rack_rate
    result = self.rack_rate
    if result < self.property.minimum_room_rate
      result = self.property.minimum_room_rate
    end
    result
  end

  # if minimum rate smaller than minimum of property then take the room type ones
  def final_minimum_rate
    # if blank just take property minimum
    if self.minimum_rate.blank?
      self.property.minimum_room_rate
    else
      # compare to property min rate, if smaller then take room type ones
      result = self.minimum_rate
      if result < self.property.minimum_room_rate
        result = self.property.minimum_room_rate
      end
      result
    end
  end

  # whether this room type has been mapped in any channel
  def mapped?
    !RoomTypeChannelMapping.find_by_room_type_id_and_disabled(self.id, false).blank?
  end

  # whether this room type has been mapped in any channel
  def mapped_to_channel?(channel)
    !RoomTypeChannelMapping.find_by_room_type_id_and_channel_id_and_disabled(self.id, channel.id, false).blank?
  end

  # room type list of a property
  def self.room_type_list(property)
    result = Array.new
    property.room_types.each do |rt|
      result << [rt.name, rt.id]
    end
    result
  end

  # room type list of a property and has mapping to channel
  def self.room_type_list_by_channel(property, channel)
    if channel.blank?
      room_type_list(property)
    else
      result = Array.new
      # check mapping to channel
      property.room_types.each do |rt|
        result << [rt.name, rt.id] if rt.mapped_to_channel?(channel)
      end
      result
    end
  end

end
