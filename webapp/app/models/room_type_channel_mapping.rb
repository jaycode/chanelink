# represent room type mapping
class RoomTypeChannelMapping < ActiveRecord::Base
  include HasSettings

  belongs_to :room_type
  belongs_to :channel

  default_scope lambda {{ :conditions => ["deleted = ?", false] }}
  scope :room_type_ids, lambda{ |room_type_ids| {:conditions => ["room_type_id IN (?)", room_type_ids]}}
  scope :channel_ids, lambda{ |channel_ids| {:conditions => ["channel_id IN (?)", channel_ids]}}
  scope :agoda_type, :conditions => "agoda_room_type_id is not null and agoda_room_type_name is not null"
  scope :expedia_type, :conditions => "expedia_room_type_id is not null and expedia_room_type_name is not null and expedia_rate_plan_id is not null"
  scope :bookingcom_type, :conditions => "bookingcom_room_type_id is not null and bookingcom_room_type_name is not null and bookingcom_rate_plan_id is not null"
  scope :gta_travel_type, :conditions => "gta_travel_room_type_id is not null"

  validates :room_type, :presence => true
  validates :channel, :presence => true
  validates :rate_configuration, :presence => true, :if => :is_rate_configuration_needed?
  validates :new_rate, :presence => true, :numericality => {:greater_than => 0, :less_than => 1000000000000}, :if => :is_configuration_new_rate?

  validates :agoda_room_type_id, :presence => true, :if => :is_channel_agoda?
  validates :agoda_room_type_name, :presence => true, :if => :is_channel_agoda?
  validates :agoda_single_rate_multiplier, :presence => true, :if => :is_channel_agoda_validate_extra?

  validates :expedia_room_type_id, :presence => true, :if => :is_channel_expedia?
  validates :expedia_room_type_name, :presence => true, :if => :is_channel_expedia?
  validates :expedia_rate_plan_id, :presence => true, :if => :is_channel_expedia?

  validates :bookingcom_room_type_id, :presence => true, :if => :is_channel_bookingcom?
  validates :bookingcom_room_type_name, :presence => true, :if => :is_channel_bookingcom?
  validates :bookingcom_rate_plan_id, :presence => true, :if => :is_channel_bookingcom?

  validates :gta_travel_room_type_id, :presence => true, :if => :is_channel_gta_travel?
  validates :gta_travel_rate_type, :presence => true, :if => :is_channel_gta_travel_validate_extra?
  validates :gta_travel_rate_margin, :presence => true, :if => :is_gta_rate_margin?

  # validates :ctrip_room_type_name, :presence => true, :if => :is_channel_ctrip?
  # validates :ctrip_room_rate_plan_category, :presence => true, :if => :is_channel_ctrip?
  # validates :ctrip_room_rate_plan_code, :presence => true, :if => :is_channel_ctrip?

  attr_accessor :skip_extra_validation
  attr_accessor :skip_rate_configuration

  attr_accessor :enabled

  validate :new_rate_must_be_greater_than_minimum

  # new rate push must be over minimum
  def new_rate_must_be_greater_than_minimum
    if self.is_configuration_new_rate?
      errors.add(:new_rate, I18n.t('room_type_channel_mappings.create.message.new_rate_should_be_greater_than_minimum', :minimum => self.room_type.final_minimum_rate)) if
       self.new_rate < self.room_type.final_minimum_rate
    end
  end

  # return channel room type id
  def channel_room_type_id
    if self.agoda_room_type_id
      self.agoda_room_type_id
    elsif self.expedia_room_type_id
      self.expedia_room_type_id
    elsif self.bookingcom_room_type_id
      self.bookingcom_room_type_id
    elsif self.gta_travel_room_type_id
      self.gta_travel_room_type_id
    elsif self.orbitz_room_type_id
      self.orbitz_room_type_id
    end
  end

  # clear all rates, inventory, min stay, cta, ctd, stop sell
  def delete
    self.update_attribute(:deleted, true)
    self.update_attribute(:disabled, true)

    room_type = self.room_type
    channel = self.channel
    pool = PropertyChannel.find_by_property_id_and_channel_id(room_type.property.id, channel.id).pool

    unless pool.blank?
      # clear rates
      ChannelRate.where(:room_type_id => room_type.id, :pool_id => pool.id, :channel_id => channel.id).each do |rate|
        rate.set_zero
      end
      # clear cta
      ChannelCta.where(:room_type_id => room_type.id, :pool_id => pool.id, :channel_id => channel.id).each do |cta|
        cta.set_false
      end
      # clear ctd
      ChannelCtd.where(:room_type_id => room_type.id, :pool_id => pool.id, :channel_id => channel.id).each do |ctd|
        ctd.set_false
      end
      # clear min stay
      ChannelMinStay.where(:room_type_id => room_type.id, :pool_id => pool.id, :channel_id => channel.id).each do |min_stay|
        min_stay.set_zero
      end
      # clear stop sell
      ChannelStopSell.where(:room_type_id => room_type.id, :pool_id => pool.id, :channel_id => channel.id).each do |stop_sell|
        stop_sell.set_false
      end
      # clear all master rate channel setting
      RoomTypeMasterRateChannelMapping.where(:room_type_id => room_type.id, :channel_id => channel.id).each do |rtm|
        rtm.update_attribute(:deleted, true)
      end
    end
  end

  def is_channel_agoda?
    self.channel == AgodaChannel.first
  end
  
  def is_channel_agoda_validate_extra?
    return false if self.skip_extra_validation
    self.is_channel_agoda?
  end

  def is_channel_expedia?
    self.channel == ExpediaChannel.first
  end

  def is_channel_bookingcom?
    self.channel == BookingcomChannel.first
  end

  def is_channel_ctrip?
    self.channel == CtripChannel.first
  end

  def is_channel_gta_travel?
    self.channel == GtaTravelChannel.first
  end

  def is_channel_gta_travel_validate_extra?
    return false if self.skip_extra_validation
    self.is_channel_gta_travel?
  end

  def is_gta_rate_margin?
    return false if !is_channel_gta_travel_validate_extra?
    if self.gta_travel_rate_type == GtaTravelChannel::RATE_MARGIN
      return true
    else
      return false
    end
  end

  def is_configuration_new_rate?
    return false if self.skip_rate_configuration
    self.rate_configuration == Constant::RTCM_NEW_RATE
  end

  def is_configuration_master_rate?
    self.rate_configuration == Constant::RTCM_MASTER_RATE
  end

  def is_rate_configuration_needed?
    if self.skip_rate_configuration
      false
    else
      true
    end
  end

  # given an amount apply the single rate discount and return it
  def calculate_bookingcom_single_rate(rate)
    if self.bookingcom_single_rate_discount.blank? or self.bookingcom_single_rate_discount == 0
      rate
    else
      rate * (1 - (self.bookingcom_single_rate_discount / 100))
    end
  end

  # method to push the rate to channel after mapping created
  def set_rate
    return if self.disabled or self.initial_rate_pushed

    # check if it using master rate or not
    if self.is_configuration_master_rate?
      logs = Array.new

      # find the master rate mapping
      master_rate_channel_mapping = RoomTypeMasterRateChannelMapping.find_by_room_type_id_and_channel_id(self.room_type_id, self.channel_id)
      master_rate = master_rate_channel_mapping.master_rate_mapping
      loop_date = DateTime.now.in_time_zone.beginning_of_day

      # loop until 400th day
      while loop_date <= Constant.maximum_end_date
        existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(loop_date, master_rate.room_type.property.id, master_rate.pool_id, master_rate.room_type_id)
        if !existing_rate.blank?
          logs << MasterRateNewRoomLog.create_master_rate_new_room_log(existing_rate)
        end
        loop_date = loop_date + 1.day
      end
      MasterRateNewRoomChangeSet.create_job(logs, master_rate.pool, self.channel, self)
    else
      rate_to_use = self.is_configuration_new_rate? ? self.new_rate : self.room_type.basic_rack_rate
      puts rate_to_use
      RateUtils.delay.populate_rate_until_day_limit(rate_to_use, self.room_type, self.channel, PropertyChannel.find_by_channel_id_and_property_id(self.channel_id, self.room_type.property.id).pool, self.room_type.property)
    end

    self.update_attribute(:initial_rate_pushed, true)
  end

  # push all availability data to channel
  def sync_availability
    room_type = self.room_type
    property = self.room_type.property
    pool = PropertyChannel.find_by_channel_id_and_property_id(self.channel.id, property.id).pool

    room_type_to_use = room_type
    if room_type.is_inventory_linked?
      room_type_to_use = room_type.linked_room_type
    end

    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      existing_inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(loop_date, property.id, pool.id, room_type_to_use.id)

      if !existing_inv.blank?
        logs << InventoryNewRoomLog.create_inventory_new_room_log(existing_inv)
      else
        inventory = Inventory.new
        inventory.date = loop_date
        inventory.total_rooms = 0
        inventory.room_type_id = room_type_to_use.id
        inventory.property = property
        inventory.pool_id = pool.id

        inventory.save

        logs << InventoryNewRoomLog.create_inventory_new_room_log(inventory)
      end

      loop_date = loop_date + 1.day
    end
    
    InventoryNewRoomChangeSet.create_job(logs, pool, self.channel, self)
  end

  # push all rate data to channel
  def sync_rate
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel
    pool = PropertyChannel.find_by_channel_id_and_property_id(self.channel.id, property.id).pool

    master_rate_channel_mapping = RoomTypeMasterRateChannelMapping.pool_id(pool.id).find_by_room_type_id_and_channel_id(room_type.id, channel.id)

    if !master_rate_channel_mapping.blank?
      logs = Array.new
      master_rate = master_rate_channel_mapping.master_rate_mapping
      loop_date = DateTime.now.in_time_zone.beginning_of_day

      # loop until 400th day
      while loop_date <= Constant.maximum_end_date
        existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(loop_date, master_rate.room_type.property.id, master_rate.pool_id, master_rate.room_type_id)
        if !existing_rate.blank?
          logs << MasterRateNewRoomLog.create_master_rate_new_room_log(existing_rate)
        end
        loop_date = loop_date + 1.day
      end

      MasterRateNewRoomChangeSet.create_job(logs, master_rate.pool, self.channel, self)

    else
      logs = Array.new
      loop_date = DateTime.now.in_time_zone.beginning_of_day

      # loop until 400th day
      while loop_date <= Constant.maximum_end_date
        channel_rate = ChannelRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_type.id, channel.id)

        if !channel_rate.blank?
          logs << ChannelRateLog.create(:channel_rate_id => channel_rate.id, :amount => channel_rate.amount)
        end

        loop_date = loop_date + 1.day
      end
      ChannelRateChangeSet.create_job(logs, pool, channel)
    end
  end

  # push all stop sell data to channel
  def sync_stop_sell
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel
    pool = PropertyChannel.find_by_channel_id_and_property_id(self.channel.id, property.id).pool

    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_stop_sell = ChannelStopSell.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_type.id, channel.id)

      if !channel_stop_sell.blank?
        ChannelStopSellLog.create(:channel_stop_sell_id => channel_stop_sell.id, :stop_sell => channel_stop_sell.stop_sell)
      end

      loop_date = loop_date + 1.day
    end
    ChannelStopSellChangeSet.create_job(logs, pool, channel)
  end

  # push all min stay data to channel
  def sync_min_stay
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel
    pool = PropertyChannel.find_by_channel_id_and_property_id(self.channel.id, property.id).pool

    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_min_stay = ChannelMinStay.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_type.id, channel.id)

      if !channel_min_stay.blank?
        ChannelMinStayLog.create(:channel_min_stay_id => channel_min_stay.id, :min_stay => channel_min_stay.min_stay)
      end

      loop_date = loop_date + 1.day
    end
    ChannelMinStayChangeSet.create_job(logs, pool, channel)
  end

  # push all cta data to channel
  def sync_cta
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel
    pool = PropertyChannel.find_by_channel_id_and_property_id(self.channel.id, property.id).pool

    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_cta = ChannelCta.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_type.id, channel.id)

      if !channel_cta.blank?
        ChannelCtaLog.create(:channel_cta_id => channel_cta.id, :cta => channel_cta.cta)
      end

      loop_date = loop_date + 1.day
    end
    ChannelCtaChangeSet.create_job(logs, pool, channel)
  end

  # push all ctd data to channel
  def sync_ctd
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel
    pool = PropertyChannel.find_by_channel_id_and_property_id(self.channel.id, property.id).pool

    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day
    
    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_ctd = ChannelCtd.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_type.id, channel.id)

      if !channel_ctd.blank?
        ChannelCtdLog.create(:channel_ctd_id => channel_ctd.id, :ctd => channel_ctd.ctd)
      end

      loop_date = loop_date + 1.day
    end
    ChannelCtdChangeSet.create_job(logs, pool, channel)
  end

  # push all cta data to channel
  def sync_gta_travel_cta
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel
    pool = PropertyChannel.find_by_channel_id_and_property_id(self.channel.id, property.id).pool

    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_cta = GtaTravelChannelCta.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_type.id, channel.id)

      if !channel_cta.blank?
        GtaTravelChannelCtaLog.create(:channel_cta_id => channel_cta.id, :cta => channel_cta.cta)
      end

      loop_date = loop_date + 1.day
    end
    GtaTravelChannelCtaChangeSet.create_job(logs, pool, channel)
  end

  # push all ctb data to channel
  def sync_gta_travel_ctb
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel
    pool = PropertyChannel.find_by_channel_id_and_property_id(self.channel.id, property.id).pool

    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_ctb = GtaTravelChannelCtb.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_type.id, channel.id)

      if !channel_ctb.blank?
        GtaTravelChannelCtbLog.create(:channel_ctb_id => channel_ctb.id, :ctb => channel_ctb.ctb)
      end

      loop_date = loop_date + 1.day
    end
    GtaTravelChannelCtbChangeSet.create_job(logs, pool, channel)
  end

  # sync all data to channel
  def sync_all_data
    return if self.disabled?
    self.sync_availability
    self.sync_rate
    self.sync_stop_sell
    self.sync_min_stay

    if self.channel == GtaTravelChannel.first
      self.sync_gta_travel_cta
      self.sync_gta_travel_ctb
    else
      self.sync_cta if Constant::SUPPORT_CTA.include?(self.channel)
      self.sync_ctd if Constant::SUPPORT_CTD.include?(self.channel)
    end
  end

  # basically update all record to have the new pool id
  def migrate_data_to_new_pool(new_pool_id, previous_pool_id)
    self.migrate_rate_to_new_pool(new_pool_id, previous_pool_id)
    self.migrate_stop_sell_to_new_pool(new_pool_id, previous_pool_id)
    self.migrate_min_stay_to_new_pool(new_pool_id, previous_pool_id)

    if self.channel == GtaTravelChannel.first
      self.migrate_gta_travel_cta_to_new_pool(new_pool_id, previous_pool_id)
      self.migrate_gta_travel_ctb_to_new_pool(new_pool_id, previous_pool_id)
    else
      self.migrate_cta_to_new_pool(new_pool_id, previous_pool_id) if Constant::SUPPORT_CTA.include?(self.channel)
      self.migrate_ctd_to_new_pool(new_pool_id, previous_pool_id) if Constant::SUPPORT_CTD.include?(self.channel)
    end
  end

  # update all rate record to have new pool id
  def migrate_rate_to_new_pool(new_pool_id, previous_pool_id)
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel

    master_rate_channel_mapping = RoomTypeMasterRateChannelMapping.pool_id(previous_pool_id).find_by_room_type_id_and_channel_id(room_type.id, channel.id)

    # check if it using master rate
    if !master_rate_channel_mapping.blank?
      master_rate = master_rate_channel_mapping.master_rate_mapping
      loop_date = DateTime.now.in_time_zone.beginning_of_day

      # loop until 400th day
      while loop_date <= Constant.maximum_end_date
        existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(loop_date, master_rate.room_type.property.id, master_rate.pool_id, master_rate.room_type_id)
        if !existing_rate.blank?
          rate = ChannelRate.new
          rate.date = existing_rate.date
          rate.amount = master_rate_channel_mapping.apply_value(existing_rate.amount)
          rate.room_type_id = existing_rate.room_type_id
          rate.property = existing_rate.property
          rate.pool_id = new_pool_id
          rate.channel = channel

          rate.save
        end
        loop_date = loop_date + 1.day
      end

    else
      loop_date = DateTime.now.in_time_zone.beginning_of_day
      
      # loop until 400th day
      while loop_date <= Constant.maximum_end_date
        channel_rate = ChannelRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, previous_pool_id, room_type.id, channel.id)

        if !channel_rate.blank?
          channel_rate.update_attribute(:pool_id, new_pool_id)
        end

        loop_date = loop_date + 1.day
      end
    end
  end

  # update all stop sell record to have new pool id
  def migrate_stop_sell_to_new_pool(new_pool_id, previous_pool_id)
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel
    
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_stop_sell = ChannelStopSell.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, previous_pool_id, room_type.id, channel.id)

      if !channel_stop_sell.blank?
        channel_stop_sell.update_attribute(:pool_id, new_pool_id)
      end

      loop_date = loop_date + 1.day
    end
  end

  # update all min stay record to have new pool id
  def migrate_min_stay_to_new_pool(new_pool_id, previous_pool_id)
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel

    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_min_stay = ChannelMinStay.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, previous_pool_id, room_type.id, channel.id)

      if !channel_min_stay.blank?
        channel_min_stay.update_attribute(:pool_id, new_pool_id)
      end

      loop_date = loop_date + 1.day
    end
  end

  # update all cta record to have new pool id
  def migrate_cta_to_new_pool(new_pool_id, previous_pool_id)
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel

    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_cta = ChannelCta.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, previous_pool_id, room_type.id, channel.id)

      if !channel_cta.blank?
        channel_cta.update_attribute(:pool_id, new_pool_id)
      end

      loop_date = loop_date + 1.day
    end
  end

  # update all ctd record to have new pool id
  def migrate_ctd_to_new_pool(new_pool_id, previous_pool_id)
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel
    
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_ctd = ChannelCtd.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, previous_pool_id, room_type.id, channel.id)

      if !channel_ctd.blank?
        channel_ctd.update_attribute(:pool_id, new_pool_id)
      end

      loop_date = loop_date + 1.day
    end
  end

  # update all cta record to have new pool id
  def migrate_gta_travel_cta_to_new_pool(new_pool_id, previous_pool_id)
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel

    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_cta = GtaTravelChannelCta.find_by_date_and_property_id_and_pool_id_and_channel_id(loop_date, property.id, previous_pool_id, channel.id)

      if !channel_cta.blank?
        channel_cta.update_attribute(:pool_id, new_pool_id)
      end

      loop_date = loop_date + 1.day
    end
  end

  # update all cta record to have new pool id
  def migrate_gta_travel_ctb_to_new_pool(new_pool_id, previous_pool_id)
    room_type = self.room_type
    property = self.room_type.property
    channel = self.channel

    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th day
    while loop_date <= Constant.maximum_end_date
      channel_ctb = GtaTravelChannelCtb.find_by_date_and_property_id_and_pool_id_and_channel_id(loop_date, property.id, previous_pool_id, channel.id)

      if !channel_ctb.blank?
        channel_ctb.update_attribute(:pool_id, new_pool_id)
      end

      loop_date = loop_date + 1.day
    end
  end

  # mapping is active if property is active and also channel mapping is active
  def active?
    pc = PropertyChannel.active_only.find_by_property_id_and_channel_id(self.room_type.property.id, self.channel_id)
    if !pc.blank?
      # check if property is active
      if !pc.property.active?
        return false
      elsif self.disabled?
        return false
      else
        return true
      end
    else
      return false
    end
  end

  # helper to decide if the mapping support single
  def gta_travel_support_single_rate_multiplier?
    if is_channel_gta_travel? and self.gta_travel_rate_basis <= 1 and self.gta_travel_max_occupancy >= 1
      return true
    else
      false
    end
  end

  # helper to decide if the mapping support double
  def gta_travel_support_double_rate_multiplier?
    if is_channel_gta_travel? and self.gta_travel_rate_basis <= 2 and self.gta_travel_max_occupancy >= 2
      return true
    else
      false
    end
  end

  # helper to decide if the mapping support triple
  def gta_travel_support_triple_rate_multiplier?
    if is_channel_gta_travel? and self.gta_travel_rate_basis <= 3 and self.gta_travel_max_occupancy >= 3
      return true
    else
      false
    end
  end

  # helper to decide if the mapping support quadruple
  def gta_travel_support_quadruple_rate_multiplier?
    if is_channel_gta_travel? and self.gta_travel_rate_basis <= 4 and self.gta_travel_max_occupancy >= 4
      return true
    else
      false
    end
  end
  
end
