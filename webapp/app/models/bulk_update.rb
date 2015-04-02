# class used to do bulk update
class BulkUpdate
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

  # all field needed to do bulk update
  attr_accessor :value_type
  attr_accessor :availability
  attr_accessor :rates
  attr_accessor :cta
  attr_accessor :ctd
  attr_accessor :ctb
  attr_accessor :stop_sell
  attr_accessor :min_stay
  attr_accessor :property

  attr_accessor :date_from
  attr_accessor :date_to
  attr_accessor :days

  attr_accessor :room_type_ids
  attr_accessor :pool_id
  attr_accessor :channel_ids
  attr_accessor :apply_to_master_rate

  # all bulk update form validations
  validates :value_type, :presence => true
  validates :availability, :presence => true, :numericality => {:greater_than => 0, :less_than => 10000000000000}, :if => :value_type_availability?
  validates :rates, :presence => true, :numericality => {:greater_than => 0, :less_than => 10000000000000}, :if => :value_type_rates?
  validates :cta, :presence => true, :if => :value_type_cta?
  validates :ctd, :presence => true, :if => :value_type_ctd?
  validates :ctb, :presence => true, :if => :value_type_ctb?
  validates :stop_sell, :presence => true, :if => :value_type_stop_sell?
  validates :min_stay, :presence => true, :numericality => {:greater_than => 0, :less_than => 10000000000000}, :if => :value_type_min_stay?
  validates :property, :presence => true

  validates :date_from, :presence => true
  validates :date_to, :presence => true
  validate :date_from_must_be_before_date_to
  validate :channel_must_presence
  validate :rates_must_be_greater_than_min_rates, :if => :value_type_rates?
  validates :days, :presence => true
  validates :room_type_ids, :presence => true, :unless => :value_type_ctb?
  
  # date from must be earlier than date to
  def date_from_must_be_before_date_to
    errors.add(:date_from, I18n.t('bulk_update.tool.label.date_from_to')) unless
       date_from <= date_to
  end

  # check if channel is specified, if needed
  def channel_must_presence
    if self.value_type.blank? or value_type_availability? or (value_type_rates? and !self.apply_to_master_rate.blank?)
      # do nothing
    elsif channel_ids.blank?
      errors.add(:channel, I18n.t('bulk_update.tool.label.channel_must_presence'))
    end
  end

  # rates used for update must be bigger than minimum rate
  def rates_must_be_greater_than_min_rates
    if !room_type_ids.blank?
      room_type_ids.each do |rt_id|
        room_type = RoomType.find(rt_id)
        if !self.rates.blank? and self.rates.to_f < room_type.final_minimum_rate
          errors.add(:channel, I18n.t('bulk_update.tool.label.rates_must_be_greater_than_min_rates', :room_type => room_type.name, :min_rate => room_type.final_minimum_rate))
        end
      end
    end
  end

  # populate value given for bulk update
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def value_type_availability?
    self.value_type == VALUE_AVAILABILITY
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

  def value_type_ctb?
    self.value_type == VALUE_CTB
  end

  # apply bulk update
  def do_update
    # check the type of bulk update
    if value_type_availability?
      update_availability
    elsif value_type_rates?
      if self.apply_to_master_rate.blank?
        update_channel_rates
      else
        update_master_rates
      end
    elsif value_type_stop_sell?
      update_stop_sell
    elsif value_type_min_stay?
      update_min_stay
    elsif value_type_cta?
      update_cta
      update_gta_travel_channel_cta
    elsif value_type_ctd?
      update_ctd
    elsif value_type_ctb?
      update_gta_travel_channel_ctb
    end
  end

  # handler for inventory bulk update
  def update_availability
    dates = dates_to_be_updated
    total_count = 0

    # go through each pool, and room type and apply update
    pools_to_be_updated.each do |pool|
      logs = Array.new
      room_type_ids.each do |rt_id|
        rt = RoomType.find(rt_id)
        next if !rt.mapped?
        puts rt.name

        # apply update on specified dates
        dates.each do |date|
          total_rooms = self.availability
          existing_inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(date, self.property.id, pool.id, rt.id)

          if existing_inv.blank?
            if total_rooms.blank? or total_rooms == 0
              # do nothing
            elsif total_rooms.to_i > 0
              inventory = Inventory.new
              inventory.date = date
              inventory.total_rooms = total_rooms
              inventory.room_type_id = rt.id
              inventory.property = self.property
              inventory.pool_id = pool.id

              inventory.save
              puts inventory.errors

              logs << MemberSetInventoryLog.create_inventory_log(inventory)
            end
          else
            if total_rooms.to_i >= 0 and (total_rooms.to_i != existing_inv.total_rooms.to_i)
              existing_inv.update_attribute(:total_rooms, total_rooms)
              logs << MemberSetInventoryLog.create_inventory_log(existing_inv)
            end
          end
        end
      end
      InventoryChangeSet.create_job(logs, pool)
      total_count = total_count + logs.size
    end
    total_count
  end

  # handler for master rate bulk update
  def update_master_rates
    dates = dates_to_be_updated
    total_count = 0

    # go through each pool, and room type and apply update
    pools_to_be_updated.each do |pool|
      logs = Array.new
      room_type_ids.each do |rt_id|
        rt = RoomType.find(rt_id)

        # skip if room type does not have master rate mapping
        next if !rt.has_master_rate_mapping?(pool)
        puts rt.name

        # apply update on dates specified
        dates.each do |date|
          amount = self.rates
          existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(date, self.property.id, pool.id, rt.id)

          if existing_rate.blank?
            if amount.blank? or amount == 0
              # do nothing
            elsif amount.to_i > 0
              rate = MasterRate.new
              rate.date = date
              rate.amount = amount
              rate.room_type_id = rt.id
              rate.property = self.property
              rate.pool_id = pool.id

              rate.save
              logs << MasterRateLog.create_master_rate_log(rate)
            end
          else
            if amount.to_i >= 0 and (amount.to_i != existing_rate.amount.to_i)
              existing_rate.update_attribute(:amount, amount)
              logs << MasterRateLog.create_master_rate_log(existing_rate)
            end
          end
        end
      end
      MasterRateChangeSet.create_job(logs, pool)
      total_count = total_count + logs.size
    end
    total_count
  end

  # handler for channel rates bulk update
  def update_channel_rates
    dates = dates_to_be_updated
    total_count = 0

    # go through each pools > channels > room type and apply update
    pools_to_be_updated.each do |pool|
      channels_to_be_updated.each do |channel|
        logs = Array.new
        pc = PropertyChannel.find_by_pool_id_and_channel_id(pool.id, channel.id)
        next if pc.blank?

        room_type_ids.each do |rt_id|
          rt = RoomType.find(rt_id)
          next if !rt.mapped_to_channel?(channel) or rt.has_master_rate_mapping_to_channel?(channel, pool)
          puts rt.name

          # apply date according to dates specified
          dates.each do |date|
            amount = self.rates
            existing_rate = ChannelRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date, self.property.id, pool.id, rt.id, channel.id)

            if existing_rate.blank?
              if amount.blank? or amount == 0
                # do nothing
              elsif amount.to_i > 0
                rate = ChannelRate.new
                rate.date = date
                rate.amount = amount
                rate.room_type_id = rt.id
                rate.property = self.property
                rate.pool = pool
                rate.channel = channel

                rate.save

                logs << ChannelRateLog.create_channel_rate_log(rate)
              end
            else
              if amount.to_i >= 0 and (amount.to_i != existing_rate.amount.to_i)
                existing_rate.update_attribute(:amount, amount)

                logs << ChannelRateLog.create_channel_rate_log(existing_rate)
              end
            end
          end
        end
        ChannelRateChangeSet.create_job(logs, pool, channel)
        total_count = total_count + logs.size
      end
    end
    total_count
  end

  # handler for channel stop sell bulk update
  def update_stop_sell
    dates = dates_to_be_updated
    total_count = 0
    # go through each pools > channels > room type and apply update
    pools_to_be_updated.each do |pool|
      channels_to_be_updated.each do |channel|
        logs = Array.new
        pc = PropertyChannel.find_by_pool_id_and_channel_id(pool.id, channel.id)
        next if pc.blank?

        room_type_ids.each do |rt_id|
          rt = RoomType.find(rt_id)
          next if !rt.mapped_to_channel?(channel)
          puts rt.name

          # apply update on dates specified
          dates.each do |date|
            stop_sell = to_boolean(self.stop_sell)
            existing_stop_sell = ChannelStopSell.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date, self.property.id, pool.id, rt.id, channel.id)

            if existing_stop_sell.blank?
              if stop_sell.blank? or !stop_sell
                # do nothing
              else
                channel_stop_sell = ChannelStopSell.new
                channel_stop_sell.date = date
                channel_stop_sell.stop_sell = true
                channel_stop_sell.room_type_id = rt.id
                channel_stop_sell.property = self.property
                channel_stop_sell.pool = pool
                channel_stop_sell.channel = channel

                channel_stop_sell.save

                logs << ChannelStopSellLog.create_channel_stop_sell_log(channel_stop_sell)
              end
            else
              if stop_sell != existing_stop_sell.stop_sell
                existing_stop_sell.update_attribute(:stop_sell, stop_sell)

                logs << ChannelStopSellLog.create_channel_stop_sell_log(existing_stop_sell)
              end
            end
          end
        end
        ChannelStopSellChangeSet.create_job(logs, pool, channel)
        puts logs.size
        total_count = total_count + logs.size
      end
    end
    total_count
  end

  # handler for channel min stay bulk update
  def update_min_stay
    dates = dates_to_be_updated
    total_count = 0
    # go through each pools > channels > room type and apply update
    pools_to_be_updated.each do |pool|
      channels_to_be_updated.each do |channel|
        logs = Array.new
        pc = PropertyChannel.find_by_pool_id_and_channel_id(pool.id, channel.id)
        next if pc.blank?

        room_type_ids.each do |rt_id|
          rt = RoomType.find(rt_id)
          next if !rt.mapped_to_channel?(channel)
          puts rt.name
          # apply update on dates specified
          dates.each do |date|
            min_stay = self.min_stay
            existing_min_stay = ChannelMinStay.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date, self.property.id, pool.id, rt.id, channel.id)

            if existing_min_stay.blank?
              if min_stay.blank? or min_stay == 0
                # do nothing
              elsif min_stay.to_i > 0
                channel_min_stay = ChannelMinStay.new
                channel_min_stay.date = date
                channel_min_stay.min_stay = min_stay
                channel_min_stay.room_type_id = rt.id
                channel_min_stay.property = self.property
                channel_min_stay.pool = pool
                channel_min_stay.channel = channel

                channel_min_stay.save

                logs << ChannelMinStayLog.create_channel_min_stay_log(channel_min_stay)
              end
            else
              if min_stay.to_i >= 0 and (min_stay.to_i != existing_min_stay.min_stay.to_i)
                existing_min_stay.update_attribute(:min_stay, min_stay)

                logs << ChannelMinStayLog.create_channel_min_stay_log(existing_min_stay)
              end
            end
          end
        end
        ChannelMinStayChangeSet.create_job(logs, pool, channel)
        puts logs.size
        total_count = total_count + logs.size
      end
    end
    total_count
  end

  # handler for channel cta bulk update
  def update_cta
    dates = dates_to_be_updated
    total_count = 0
    channels_to_be_updated.delete(GtaTravelChannel.first)

    # go through each pools > channels > room type and apply update
    pools_to_be_updated.each do |pool|
      channels_to_be_updated.each do |channel|
        logs = Array.new
        pc = PropertyChannel.find_by_pool_id_and_channel_id(pool.id, channel.id)
        next if pc.blank?

        room_type_ids.each do |rt_id|
          rt = RoomType.find(rt_id)
          next if !rt.mapped_to_channel?(channel)
          puts rt.name
          # apply update on dates specified
          dates.each do |date|
            cta = to_boolean(self.cta)
            existing_cta = ChannelCta.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date, self.property.id, pool.id, rt.id, channel.id)

            if existing_cta.blank?
              if !cta
                # do nothing
              else
                channel_cta = ChannelCta.new
                channel_cta.date = date
                channel_cta.cta = true
                channel_cta.room_type_id = rt.id
                channel_cta.property = self.property
                channel_cta.pool = pool
                channel_cta.channel = channel

                channel_cta.save

                logs << ChannelCtaLog.create_channel_cta_log(channel_cta)
              end
            else
              if cta != existing_cta.cta
                existing_cta.update_attribute(:cta, cta)
                logs << ChannelCtaLog.create_channel_cta_log(existing_cta)
              end
            end
          end
        end
        ChannelCtaChangeSet.create_job(logs, pool, channel)
        puts logs.size
        total_count = total_count + logs.size
      end
    end
    total_count
  end

  # handler for channel cta bulk update
  def update_gta_travel_channel_cta
    dates = dates_to_be_updated
    total_count = 0
    gta_channel = GtaTravelChannel.first
    
    return if !channels_to_be_updated.include?(gta_channel)

    # go through each pools > channels > room type and apply update
    pools_to_be_updated.each do |pool|
      logs = Array.new
      pc = PropertyChannel.find_by_pool_id_and_channel_id(pool.id, gta_channel.id)
      next if pc.blank?

      dates.each do |date|
        cta = to_boolean(self.cta)
        existing_cta = GtaTravelChannelCta.find_by_date_and_property_id_and_pool_id_and_channel_id(date, self.property.id, pool.id, gta_channel.id)

        if existing_cta.blank?
          if !cta
            # do nothing
          else
            channel_cta = GtaTravelChannelCta.new
            channel_cta.date = date
            channel_cta.cta = true
            channel_cta.property = self.property
            channel_cta.pool = pool
            channel_cta.channel = gta_channel

            channel_cta.save

            logs << GtaTravelChannelCtaLog.create_gta_travel_channel_cta_log(channel_cta)
          end
        else
          if cta != existing_cta.cta
            existing_cta.update_attribute(:cta, cta)
            logs << GtaTravelChannelCtaLog.create_gta_travel_channel_cta_log(existing_cta)
          end
        end
      end
      
      GtaTravelChannelCtaChangeSet.create_job(logs, pool)
      total_count = total_count + logs.size
    end
    total_count
  end

  # handler for channel ctd bulk update
  def update_ctd
    dates = dates_to_be_updated
    total_count = 0
    # go through each pools > channels > room type and apply update
    pools_to_be_updated.each do |pool|
      channels_to_be_updated.each do |channel|
        logs = Array.new
        pc = PropertyChannel.find_by_pool_id_and_channel_id(pool.id, channel.id)
        next if pc.blank?

        room_type_ids.each do |rt_id|
          rt = RoomType.find(rt_id)
          next if !rt.mapped_to_channel?(channel)
          puts rt.name

          # apply update on dates specified
          dates.each do |date|
            ctd = to_boolean(self.ctd)
            existing_ctd = ChannelCtd.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date, self.property.id, pool.id, rt.id, channel.id)

            if existing_ctd.blank?
              if !ctd
                # do nothing
              else
                channel_ctd = ChannelCtd.new
                channel_ctd.date = date
                channel_ctd.ctd = true
                channel_ctd.room_type_id = rt.id
                channel_ctd.property = self.property
                channel_ctd.pool = pool
                channel_ctd.channel = channel

                channel_ctd.save

                logs << ChannelCtdLog.create_channel_ctd_log(channel_ctd)
              end
            else
              if ctd != existing_ctd.ctd
                existing_ctd.update_attribute(:ctd, ctd)
                logs << ChannelCtdLog.create_channel_ctd_log(existing_ctd)
              end
            end
          end
        end
        ChannelCtdChangeSet.create_job(logs, pool, channel)
        puts logs.size
        total_count = total_count + logs.size
      end
    end
    total_count
  end

  # handler for channel cta bulk update
  def update_gta_travel_channel_ctb
    dates = dates_to_be_updated
    total_count = 0
    gta_channel = GtaTravelChannel.first

    return if !channels_to_be_updated.include?(gta_channel)

    puts 'dads dad '

    # go through each pools > channels > room type and apply update
    pools_to_be_updated.each do |pool|

      puts 'dads dad '
      logs = Array.new
      pc = PropertyChannel.find_by_pool_id_and_channel_id(pool.id, gta_channel.id)
      next if pc.blank?

      dates.each do |date|
        puts 'dads dad '
        ctb = to_boolean(self.ctb)
        existing_ctb = GtaTravelChannelCtb.find_by_date_and_property_id_and_pool_id_and_channel_id(date, self.property.id, pool.id, gta_channel.id)

        if existing_ctb.blank?
          if !ctb
            # do nothing
          else
            channel_ctb = GtaTravelChannelCtb.new
            channel_ctb.date = date
            channel_ctb.ctb = true
            channel_ctb.property = self.property
            channel_ctb.pool = pool
            channel_ctb.channel = gta_channel

            channel_ctb.save

            logs << GtaTravelChannelCtbLog.create_gta_travel_channel_ctb_log(channel_ctb)
          end
        else
          if ctb != existing_ctb.ctb
            existing_ctb.update_attribute(:ctb, ctb)
            logs << GtaTravelChannelCtbLog.create_gta_travel_channel_ctb_log(existing_ctb)
          end
        end
      end

      GtaTravelChannelCtbChangeSet.create_job(logs, pool)
      total_count = total_count + logs.size
    end
    total_count
  end

  # return list of dates need to be updated
  def dates_to_be_updated
    result = Array.new
    start_date = Date.strptime(date_from)
    end_date = Date.strptime(date_to)

    # include the dates according to day specified
    while start_date <= end_date
      result << start_date.strftime(Constant::GRID_DATE_FORMAT) if days.include?(start_date.wday.to_s)
      start_date = start_date + 1.day
    end
    result
  end

  # pools that needs to be updates
  def pools_to_be_updated
    result = Array.new

    # if property has one pool
    if property.single_pool?
      result = property.pools
    # all pool
    elsif pool_id == Constant::ALL
      result = property.pools
    else
      result << Pool.find(pool_id)
    end

    result
  end

  # list of channels to be updated
  def channels_to_be_updated
    result = Array.new

    channel_ids.each do |channel_id|
      result << Channel.find(channel_id)
    end

    result
  end

  # helper to handle boolean value
  def to_boolean(value)
    value == Constant::ON ? true : false
  end

end