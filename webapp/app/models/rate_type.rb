class RateType < ActiveRecord::Base
  belongs_to :account
  has_many :room_type_channel_mappings
  default_scope lambda {{ :conditions => ["`rate_types`.deleted = ?", false] }}

  # clean up all links that was made to this rate type
  def clean_up
    if self.deleted?
      # clean rate type mapping
      RoomTypeChannelMapping.find_all_by_rate_type_id(self.id).each do |rtcm|
        rtcm.update_attribute(:deleted, true)
      end
      # clean master rate mapping
      RoomTypeMasterRateMapping.find_all_by_rate_type_id(self.id).each do |rtmr|
        RoomTypeMasterRateChannelMapping.find_all_by_rate_type_master_rate_mapping_id(rtmr.id).each do |rtc|
          rtc.update_attribute(:deleted, true)
        end
        rtmr.update_attribute(:deleted, true)
      end
    end
  end


end