# represent a channel mapping to a property
# Todo: Instead of putting keys for OTAs as fields here, use "settings" field and put OTA details there.
class PropertyChannel < ActiveRecord::Base

  extend Unscoped

  belongs_to :property
  belongs_to :channel
  belongs_to :pool
  has_one :currency_conversion

  unscope :property, :pool

  validates :property, :presence => true
  validates :channel, :presence => true
  validates :pool, :presence => true

  validates :rate_conversion_multiplier, :allow_nil => true, :numericality => {:greater_than => 0.5, :less_than => 10000000000000}, :if => :is_validate_rate_conversion_multiplier?
  
  #validates :agoda_currency, :presence => true, :if => :is_validate_agoda_info?
  validates :agoda_username, :presence => true, :if => :is_validate_agoda_info?
  validates :agoda_password, :presence => true, :if => :is_validate_agoda_info?

  validates :expedia_reservation_email_address, :presence => true, :format => { :with => /^[^@][\w.-]+@[\w.-]+[.][a-z]{2,4}$/i}, :if => :is_validate_expedia_info?
  validates :expedia_modification_email_address, :presence => true, :format => { :with => /^[^@][\w.-]+@[\w.-]+[.][a-z]{2,4}$/i}, :if => :is_validate_expedia_info?
  validates :expedia_cancellation_email_address, :presence => true, :format => { :with => /^[^@][\w.-]+@[\w.-]+[.][a-z]{2,4}$/i}, :if => :is_validate_expedia_info?
  #validates :expedia_currency, :presence => true, :if => :is_validate_expedia_info?

  validates :bookingcom_username, :presence => true, :if => :is_validate_bookingcom_info?
  validates :bookingcom_password, :presence => true, :if => :is_validate_bookingcom_info?
  validates :bookingcom_reservation_email_address, :presence => true, :format => { :with => /^[^@][\w.-]+@[\w.-]+[.][a-z]{2,4}$/i}, :if => :is_validate_bookingcom_info?

  validates :tiketcom_hotel_key, :presence => true, :if => :is_validate_tiketcom_info?

  validates :gta_travel_property_id, :presence => true, :if => :is_validate_gta_travel_info?

  validates :ctrip_hotel_code, :presence => true, :if => :is_validate_ctrip_info?

  # validates :orbitz_hotel_code, :presence => true, :if => :is_validate_orbitz_info?
  # validates :orbitz_chain_code, :presence => true, :if => :is_validate_orbitz_info?

  default_scope lambda {{ :conditions => ["deleted = ?", false] }}
  scope :not_approved, lambda { {:conditions => ["approved = ?", false]} }
  scope :active_only, lambda { {:conditions => ["disabled = ?", false]} }
  scope :disabled, lambda { {:conditions => ["disabled = ?", true]} }

  accepts_nested_attributes_for :currency_conversion

  attr_accessor :skip_channel_specific
  attr_accessor :skip_rate_conversion_multiplier
  attr_accessor :previous_pool_id

  after_create :notify_backoffice

  def is_validate_agoda_info?
    return false if self.skip_channel_specific
    self.channel == AgodaChannel.first
  end

  def is_validate_expedia_info?
    return false if self.skip_channel_specific
    self.channel == ExpediaChannel.first
  end

  def is_validate_bookingcom_info?
    return false if self.skip_channel_specific
    self.channel == BookingcomChannel.first
  end

  def is_validate_tiketcom_info?
    return false if self.skip_channel_specific
    self.channel == TiketcomChannel.first
  end

  def is_validate_ctrip_info?
    return false if self.skip_channel_specific
    self.channel == CtripChannel.first
  end

  def is_validate_orbitz_info?
    return false if self.skip_channel_specific
    self.channel == OrbitzChannel.first
  end

  def is_validate_gta_travel_info?
    return false if self.skip_channel_specific
    self.channel == GtaTravelChannel.first
  end

  def is_validate_rate_conversion_multiplier?
    return false if self.skip_rate_conversion_multiplier
    true
  end

  # sync all channel data to OTA
  def sync_all_data
    return if self.disabled?
    self.channel.class.get_all_room_type_mapping(self.property).each do |rtcm|
      rtcm.delay.sync_all_data
    end
  end

  # change all record of this mapping to a new pool
  def migrate_room_data_to_new_pool
    return if self.previous_pool_id.blank?

    # find all the mapping
    self.channel.class.get_all_room_type_mapping(self.property).each do |rtcm|
      rtcm.migrate_data_to_new_pool(self.pool_id, self.previous_pool_id)
    end
    
  end

  # delete all master rate mapping
  def delete_all_master_rate_mapping
    RoomTypeMasterRateChannelMapping.pool_id(self.previous_pool_id).find_all_by_channel_id(self.channel.id).each do |rtcm|
      rtcm.update_attribute(:deleted, true)
    end
  end

  # check if this mapping enabled and approved
  def enabled_and_approved?
    if self.disabled == false and self.approved == true
      true
    else
      false
    end
  end

  # delete this channel mapping
  def delete
    RoomTypeChannelMapping.room_type_ids(self.property.room_type_ids).where(:channel_id => self.channel.id).each do |rtcm|
      rtcm.delete
    end
    RoomTypeMasterRateChannelMapping.pool_id(self.pool_id).find_all_by_channel_id(self.channel.id).each do |rtcm|
      rtcm.update_attribute(:deleted, true)
    end
    self.update_attributes(:deleted => true, :disabled => true)
  end

  # Getter. *params is parameters in hierarchial order,
  # e.g. settings(:ota, :username) will get {:ota => {:username => 'this value'}}.
  # If no params given, give the json decoded settings
  def settings(*params)
    obj = JSON.parse(read_attribute(:settings))
    if params.empty?
      obj
    else
      params.each do |p|
        puts "obj-#{p}: #{obj[p.to_s]}"
        obj = obj[p.to_s]
      end
    end
  end

  def settings=(params)
    settings_json = settings.merge(params)
    write_attribute(:settings, ActiveSupport::JSON.encode(settings_json))
  end

  def destroy_settings
    write_attribute(:settings, ActiveSupport::JSON.encode({__default: {}}))
  end

  private

  def notify_backoffice
    User.where('super = true').each do |user|
      TeamNotifier.delay.email_new_property_channel(self, user)
    end
  end

end
