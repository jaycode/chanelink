# represent each channel setting to a master rate room
# Todo: May need to be combined into RoomTypeChannelMapping.
class RoomTypeMasterRateChannelMapping < ActiveRecord::Base

  default_scope lambda {{ :conditions => ["room_type_master_rate_channel_mappings.deleted = ?", false] }}

  belongs_to :master_rate_mapping, :class_name => 'RoomTypeMasterRateMapping', :foreign_key => 'room_type_master_rate_mapping_id'
  belongs_to :channel
  belongs_to :room_type
  belongs_to :rate_type_property_channel

  scope :room_type_ids_in, lambda { |room_type_ids| {:conditions => ["room_type_master_rate_channel_mappings.room_type_id IN (?)", room_type_ids]} }
  scope :master_room_type_id, lambda { |room_type_id| {:conditions => ["room_type_master_rate_mappings.room_type_id = ?", room_type_id], :include => [:master_rate_mapping]} }
  scope :pool_id, lambda { |pool_id| {:conditions => ["room_type_master_rate_mappings.pool_id = ?", pool_id], :include => [:master_rate_mapping]} }

  validates :master_rate_mapping, :presence => true
  validates :channel, :presence => true
  validates :room_type, :presence => true
  validates :percentage, :presence => true, :numericality => {:greater_than => -100, :less_than => 1000}, :if => :method_percentage?
  validates :value, :presence => true, :numericality => {:greater_than => -1000000000000, :less_than => 1000000000000}, :if => :method_amount?

  PERCENTAGE = 'percentage'
  AMOUNT = 'amount'

  # return the value method
  def method
    if self[:method].blank?
      PERCENTAGE
    else
      self[:method]
    end
  end

  def method_percentage?
    if self.method == PERCENTAGE
      true
    else
      false
    end
  end

  def method_amount?
    if self.method == AMOUNT
      true
    else
      false
    end
  end

  # apply the markup/markdown value
  def apply_value(amount)
    if self.method == PERCENTAGE
      amount * (1 + (self.percentage.to_i/100.0))
    elsif self.method == AMOUNT
      amount + self.value
    end
  end

  # sync data to the channel
  def sync_rate
    rtcm = RoomTypeChannelMapping.find_by_channel_id_and_room_type_id(self.channel.id, self.room_type.id)
    rtcm.sync_rate
  end
  
end
