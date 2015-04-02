# represent master rate mapping
class RoomTypeMasterRateMapping < ActiveRecord::Base

  default_scope lambda {{ :conditions => ["room_type_master_rate_mappings.deleted = ?", false] }}
  
  belongs_to :pool
  belongs_to :room_type
  has_many :channel_mappings, :class_name => 'RoomTypeMasterRateChannelMapping', :foreign_key => 'room_type_master_rate_mapping_id'

  validates :room_type, :presence => true
  validates :pool, :presence => true

  validate :must_be_unique

  # make sure room type is not a master rate room before
  def must_be_unique
    errors.add(:failed, I18n.t('room_type_master_rate_mappings.create.message.already_exist')) if
      !RoomTypeMasterRateMapping.find_by_pool_id_and_room_type_id(self.pool_id, self.room_type_id).blank?
  end

  # list of all master rate mapping
  def self.select_list(pool)
    result = Array.new
    result << [I18n.t('room_type_master_rate_mappings.placeholder'), nil]
    RoomTypeMasterRateMapping.find_all_by_pool_id(pool.id).each do |mapping|
      result << [mapping.room_type.name, mapping.id]
    end
    result
  end

end
