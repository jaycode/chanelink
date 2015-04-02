# class to run copy tool operation
class CopyTool
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  VALUE_AVAILABILITY = 'availability'
  VALUE_RATES = 'rates'
  VALUE_STOP_SELL = 'stop_sell'
  VALUE_MIN_STAY = 'min_stay'
  VALUE_CTA = 'cta'
  VALUE_CTD = 'ctd'
  VALUE_CTB = 'ctb'

  # fields passed from the form
  attr_accessor :pool_id
  attr_accessor :value_type
  attr_accessor :channel_id_from
  attr_accessor :channel_id_to
  attr_accessor :room_id_from
  attr_accessor :room_id_to
  attr_accessor :property

  # validations
  validates :value_type, :presence => true
  validates :pool_id, :presence => true, :if => :property_multiple_pool?
  validates :channel_id_from, :presence => true
  validates :channel_id_to, :presence => true
  validates :room_id_from, :presence => true, :unless => :channel_from_gta_travel?
  validates :room_id_to, :presence => true, :unless => :cta_channel_to_or_from_gta_travel?
  validates :property, :presence => true

  validate :channel_and_room_must_be_different

  validate :room_to_must_not_link_to_master_rate

  # make sure we are not copying to the same room type
  def channel_and_room_must_be_different
    errors.add(:date_from, I18n.t('copy_tool.tool.label.channel_room_must_be_different')) if
       channel_id_from == channel_id_to and room_id_from == room_id_to
  end

  # not used as of now, room from can be from a master rate room
  def room_from_must_not_link_to_master_rate
    if !room_id_from.blank? and !channel_id_from.blank?
      room_type = RoomType.find(room_id_from)
      channel = Channel.find(channel_id_from)
      pool = property.single_pool? ? property.pools.first : Pool.find(pool_id)
      errors.add(:room_from, I18n.t('copy_tool.tool.label.no_master_rate_link', :room_type => room_type.name, :channel => channel.name)) if
         room_type.has_master_rate_mapping_to_channel?(channel, pool)
    end
  end

  # room to must not link to master rate
  def room_to_must_not_link_to_master_rate
    if !room_id_to.blank? and !channel_id_to.blank?
      room_type = RoomType.find(room_id_to)
      channel = Channel.find(channel_id_to)
      pool = property.single_pool? ? property.pools.first : Pool.find(pool_id)
      errors.add(:room_to, I18n.t('copy_tool.tool.label.no_master_rate_link', :room_type => room_type.name, :channel => channel.name)) if
         room_type.has_master_rate_mapping_to_channel?(channel, pool)
    end
  end
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def value_type_rates?
    self.value_type == VALUE_RATES
  end

  def value_type_stop_sell?
    self.value_type == VALUE_STOP_SELL
  end

  def value_type_min_stay?
    self.value_type == VALUE_MIN_STAY
  end

  def value_type_cta?
    self.value_type == VALUE_CTA
  end

  def value_type_ctd?
    self.value_type == VALUE_CTD
  end

  def channel_from_gta_travel?
    channel_from == GtaTravelChannel.first
  end

  def cta_channel_to_or_from_gta_travel?
    value_type_cta? and (channel_from == GtaTravelChannel.first or channel_to == GtaTravelChannel.first)
  end

  def channel_to_gta_travel?
    channel_to == GtaTravelChannel.first
  end

  # check if given property has more than one pool
  def property_multiple_pool?
    !property.single_pool?
  end

  # the actual copy operation
  def do_update
    if value_type_rates?
      copy_rates
    elsif value_type_stop_sell?
      copy_stop_sell
    elsif value_type_min_stay?
      copy_min_stay
    elsif value_type_cta?
      if channel_from == GtaTravelChannel.first
        copy_cta_from_gta_travel
      else
        copy_cta
      end
    elsif value_type_ctd?
      copy_ctd
    elsif value_type_ctb?
      copy_ctb
    end
  end

  # get pool object to run copy tool
  def pool_to_be_updated
    if property.single_pool?
      property.pools.first
    else
      Pool.find(pool_id)
    end
  end

  # get channel object for channel_to
  def channel_to
    Channel.find(channel_id_to)
  end

  # get channel object for channel_from
  def channel_from
    Channel.find(channel_id_from)
  end

  # handle copying min stay
  def copy_min_stay
    pool = pool_to_be_updated
    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until the next 400 days
    while loop_date <= Constant.maximum_end_date
      source_min_stay = ChannelMinStay.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_from, channel_id_from)
      min_stay_to_copy = source_min_stay.blank? ? 0 : source_min_stay.min_stay

      dest_min_stay = ChannelMinStay.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_to, channel_id_to)

      # if record not blank then do update, if blank then create new
      if dest_min_stay.blank?
        channel_min_stay = ChannelMinStay.new
        channel_min_stay.date = loop_date
        channel_min_stay.min_stay = min_stay_to_copy
        channel_min_stay.room_type_id = room_id_to
        channel_min_stay.property = property
        channel_min_stay.pool = pool
        channel_min_stay.channel_id = channel_id_to

        channel_min_stay.save

        logs << ChannelMinStayLog.create_channel_min_stay_log(channel_min_stay)
      else
        dest_min_stay.update_attribute(:min_stay, min_stay_to_copy)
        logs << ChannelMinStayLog.create_channel_min_stay_log(dest_min_stay)
      end
      puts "#{loop_date} #{logs.size}"
      loop_date = loop_date + 1.day
    end

    ChannelMinStayChangeSet.create_job(logs, pool, channel_to)
  end

  # handle copying rates
  def copy_rates
    pool = pool_to_be_updated
    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    room_from_use_master_rate = RoomType.find(room_id_from).has_master_rate_mapping_to_channel?(Channel.find(channel_id_from), pool)

    # loop until the next 400 days
    while loop_date <= Constant.maximum_end_date
      source_rate = nil
      amount_to_copy = nil

      # check if room from user master rates or not
      # then find rate to copy accordingly
      if room_from_use_master_rate
        rtcm = RoomTypeMasterRateChannelMapping.find_by_room_type_id_and_channel_id(room_id_from, channel_id_from)
        master_room = rtcm.master_rate_mapping.room_type
        source_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(loop_date, property.id, pool.id, master_room.id)
        amount_to_copy = source_rate.blank? ? 0 : rtcm.apply_value(source_rate.amount)
      else
        source_rate = ChannelRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_from, channel_id_from)
        amount_to_copy = source_rate.blank? ? 0 : source_rate.amount
      end
      
      dest_rate = ChannelRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_to, channel_id_to)

      # if record not blank then do update, if blank then create new
      if dest_rate.blank?
        channel_rate = ChannelRate.new
        channel_rate.date = loop_date
        channel_rate.amount = amount_to_copy
        channel_rate.room_type_id = room_id_to
        channel_rate.property = property
        channel_rate.pool = pool
        channel_rate.channel_id = channel_id_to

        channel_rate.save

        logs << ChannelRateLog.create_channel_rate_log(channel_rate)
      else
        dest_rate.update_attribute(:amount, amount_to_copy)
        logs << ChannelRateLog.create_channel_rate_log(dest_rate)
      end
      puts "#{loop_date} #{logs.size}"
      loop_date = loop_date + 1.day
    end

    ChannelRateChangeSet.create_job(logs, pool, channel_to)
  end

  # handle copying stop sell
  def copy_stop_sell
    pool = pool_to_be_updated
    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until the next 400 days
    while loop_date <= Constant.maximum_end_date
      source_stop_sell = ChannelStopSell.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_from, channel_id_from)
      stop_sell_to_copy = source_stop_sell.blank? ? false : source_stop_sell.stop_sell

      dest_stop_sell = ChannelStopSell.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_to, channel_id_to)

      # if record not blank then do update, if blank then create new
      if dest_stop_sell.blank?
        channel_stop_sell = ChannelStopSell.new
        channel_stop_sell.date = loop_date
        channel_stop_sell.stop_sell = stop_sell_to_copy
        channel_stop_sell.room_type_id = dest_stop_sell.room_type_id
        channel_stop_sell.property = dest_stop_sell.property
        channel_stop_sell.pool = dest_stop_sell.pool
        channel_stop_sell.channel = dest_stop_sell.channel

        channel_stop_sell.save

        logs << ChannelStopSellLog.create_channel_stop_sell_log(channel_stop_sell)
      else
        dest_stop_sell.update_attribute(:stop_sell, stop_sell_to_copy)
        logs << ChannelStopSellLog.create_channel_stop_sell_log(dest_stop_sell)
      end
      puts "#{loop_date} #{logs.size}"
      loop_date = loop_date + 1.day
    end

    ChannelStopSellChangeSet.create_job(logs, pool, channel_to)
  end

  # handle copying cta
  def copy_cta
    pool = pool_to_be_updated
    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until the next 400 days
    while loop_date <= Constant.maximum_end_date

      source_cta = ChannelCta.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_from, channel_id_from)
      
      cta_to_copy = source_cta.blank? ? false : source_cta.cta

      dest_cta = ChannelCta.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_to, channel_id_to)

      # if record not blank then do update, if blank then create new
      if dest_cta.blank?
        channel_cta = ChannelCta.new
        channel_cta.date = loop_date
        channel_cta.cta = cta_to_copy
        channel_cta.room_type_id = room_id_to
        channel_cta.property = property
        channel_cta.pool = pool
        channel_cta.channel = channel_to

        channel_cta.save

        logs << ChannelCtaLog.create_channel_cta_log(channel_cta)
      else
        dest_cta.update_attribute(:cta, cta_to_copy)
        logs << ChannelCtaLog.create_channel_cta_log(dest_cta)
      end
      puts "#{loop_date} #{logs.size}"
      loop_date = loop_date + 1.day
    end

    ChannelCtaChangeSet.create_job(logs, pool, channel_to)
  end

  # handle copying cta
  def copy_cta_from_gta_travel
    pool = pool_to_be_updated
    
    property.room_types.each do |rt|
      logs = Array.new
      loop_date = DateTime.now.in_time_zone.beginning_of_day

      puts "#{rt.id}"

      target_room_type_id = rt.id
      # loop until the next 400 days
      while loop_date <= Constant.maximum_end_date

        puts "#{loop_date}"

        source_cta = GtaTravelChannelCta.find_by_date_and_property_id_and_pool_id_and_channel_id(loop_date, property.id, pool.id, channel_id_from)

        cta_to_copy = source_cta.blank? ? false : source_cta.cta

        dest_cta = ChannelCta.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, target_room_type_id, channel_id_to)

        # if record not blank then do update, if blank then create new
        if dest_cta.blank?
          channel_cta = ChannelCta.new
          channel_cta.date = loop_date
          channel_cta.cta = cta_to_copy
          channel_cta.room_type_id = target_room_type_id
          channel_cta.property = property
          channel_cta.pool = pool
          channel_cta.channel = channel_to

          channel_cta.save

          logs << ChannelCtaLog.create_channel_cta_log(channel_cta)
        else
          dest_cta.update_attribute(:cta, cta_to_copy)
          logs << ChannelCtaLog.create_channel_cta_log(dest_cta)
        end
        puts "#{loop_date} #{logs.size}"
        loop_date = loop_date + 1.day
      end

      ChannelCtaChangeSet.create_job(logs, pool, channel_to)
    end
  end

  # handle copying ctd
  def copy_ctd
    pool = pool_to_be_updated
    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until the next 400 days
    while loop_date <= Constant.maximum_end_date
      source_ctd = ChannelCtd.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_from, channel_id_from)
      ctd_to_copy = source_ctd.blank? ? false : source_ctd.ctd

      dest_ctd = ChannelCtd.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_to, channel_id_to)

      # if record not blank then do update, if blank then create new
      if dest_ctd.blank?
        channel_ctd = ChannelCtd.new
        channel_ctd.date = loop_date
        channel_ctd.ctd = ctd_to_copy
        channel_ctd.room_type_id = room_id_to
        channel_ctd.property = property
        channel_ctd.pool = pool
        channel_ctd.channel_id = channel_id_to

        channel_ctd.save

        logs << ChannelCtdLog.create_channel_ctd_log(channel_ctd)
      else
        dest_ctd.update_attribute(:ctd, ctd_to_copy)
        logs << ChannelCtdLog.create_channel_ctd_log(dest_ctd)
      end
      puts "#{loop_date} #{logs.size}"
      loop_date = loop_date + 1.day
    end

    ChannelCtdChangeSet.create_job(logs, pool, channel_to)
  end

  # handle copying ctb
  def copy_ctb
#    pool = pool_to_be_updated
#    logs = Array.new
#    loop_date = DateTime.now.in_time_zone.beginning_of_day
#
#    # loop until the next 400 days
#    while loop_date <= Constant.maximum_end_date
#      source_ctb = ChannelCtd.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_from, channel_id_from)
#      ctb_to_copy = source_ctb.blank? ? false : source_ctb.ctb
#
#      dest_ctb = ChannelCtd.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_id_to, channel_id_to)
#
#      # if record not blank then do update, if blank then create new
#      if dest_ctd.blank?
#        channel_ctb = ChannelCtd.new
#        channel_ctb.date = loop_date
#        channel_ctb.ctd = ctd_to_copy
#        channel_ctb.room_type_id = room_id_to
#        channel_ctb.property = property
#        channel_ctb.pool = pool
#        channel_ctb.channel_id = channel_id_to
#
#        channel_ctb.save
#
#        logs << ChannelCtdLog.create_channel_ctd_log(channel_ctd)
#      else
#        dest_ctd.update_attribute(:ctd, ctd_to_copy)
#        logs << ChannelCtdLog.create_channel_ctd_log(dest_ctd)
#      end
#      puts "#{loop_date} #{logs.size}"
#      loop_date = loop_date + 1.day
#    end
#
#    ChannelCtdChangeSet.create_job(logs, pool, channel_to)
  end

  # used for UI form
  def self.value_type_list
    result = Array.new
    result << [I18n.t('bulk_update.tool.label.rates'), VALUE_RATES]
    result << [I18n.t('inventories.grid.label.stop_sell'), VALUE_STOP_SELL]
    result << [I18n.t('inventories.grid.label.min_stay'), VALUE_MIN_STAY]
    result << [I18n.t('inventories.grid.label.cta'), VALUE_CTA]
    result << [I18n.t('inventories.grid.label.ctd'), VALUE_CTD]
    result
  end
  
end