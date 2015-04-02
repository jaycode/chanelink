# controller to handle channel rates form submit in inventory grid
class ChannelRatesController < ApplicationController

  before_filter :member_authenticate_and_property_selected
  before_filter :check_requirement

  # the main method to handle the data
  def update
    @pool = Pool.find(params[:pool_id])
    if validate_channel_rates
      do_update
      redirect_to grid_inventories_path(:pool_id => @pool.id)
    else
      redirect_to grid_inventories_path(:pool_id => @pool.id), :flash => {"#{@channel.cname}_rates" => params}
    end
  end

  # check is all data submitted is valid
  def validate_channel_rates
    result = true
    errors = Array.new

    # go through all value submitted do validate them: must be a number and not less than the minimum
    current_property.room_types.each do |rt|
      if params["#{rt.id}"]
        params["#{rt.id}"].each do |date_rate|

          # make sure min stay is positive integer and not less than minimum of the property/room-type
          if date_rate[1]["amount"]
            amount = date_rate[1]["amount"]
            if !(amount =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/)
              errors << t('channel_rates.validate.error_not_a_number', :channel => @channel.name, :room_type => rt.name, :date => date_rate[0])
            elsif amount.to_f < 0
              errors << t('channel_rates.validate.error_negative_number', :channel => @channel.name, :room_type => rt.name, :date => date_rate[0])
            elsif amount.to_f < rt.final_minimum_rate
              errors << t('channel_rates.validate.error_less_than_minimum', :channel => @channel.name, :room_type => rt.name, :date => date_rate[0], :minimum => rt.final_minimum_rate)
            end
          end

          # make sure min stay is positive integer
          if date_rate[1]["min_stay"]
            min_stay = date_rate[1]["min_stay"]
            if !(min_stay =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/)
              errors << t('channel_rates.validate.error_min_stay_not_a_number', :channel => @channel.name, :room_type => rt.name, :date => date_rate[0])
            elsif min_stay.to_i < 0
              errors << t('channel_rates.validate.error_min_stay_negative_number', :channel => @channel.name, :room_type => rt.name, :date => date_rate[0])
            end
          end
        end
      end
    end

    if !errors.empty?
      flash[:alert] = errors
      result = false
    end

    result
  end

  # method to do the actual update
  def do_update
    
    amount_logs = Array.new
    stop_sell_logs = Array.new
    min_stay_logs = Array.new
    cta_logs = Array.new
    ctd_logs = Array.new
    
    pool = Pool.find(params[:pool_id])

    # go through all the data submitted and pass it to all the handler
    current_property.room_types.each do |rt|
      if params["#{rt.id}"]
        params["#{rt.id}"].each do |date_rate|
          handle_amount(date_rate, rt, amount_logs)
          handle_stop_sell(date_rate, rt, stop_sell_logs)
          handle_min_stay(date_rate, rt, min_stay_logs)
          handle_cta(date_rate, rt, cta_logs) if Constant::SUPPORT_CTA.include?(@channel)
          handle_ctd(date_rate, rt, ctd_logs) if Constant::SUPPORT_CTD.include?(@channel)
        end
      end
    end

    # gta travel specific
    if @channel == GtaTravelChannel.first
      gta_travel_cta_logs = Array.new
      gta_travel_ctb_logs = Array.new

      if params["cta"]
        params["cta"].each do |date_rate|
          handle_gta_travel_channel_cta(date_rate, gta_travel_cta_logs)
        end
      end

      if params["ctb"]
        params["ctb"].each do |date_rate|
          handle_gta_travel_channel_ctb(date_rate, gta_travel_ctb_logs)
        end
      end

      GtaTravelChannelCtaChangeSet.create_job(gta_travel_cta_logs, pool)
      GtaTravelChannelCtbChangeSet.create_job(gta_travel_ctb_logs, pool)
    end

    # each value type data is a change set, create the change set according to the type
    ChannelRateChangeSet.create_job(amount_logs, pool, @channel)
    ChannelStopSellChangeSet.create_job(stop_sell_logs, pool, @channel)
    ChannelMinStayChangeSet.create_job(min_stay_logs, pool, @channel)
    ChannelCtaChangeSet.create_job(cta_logs, pool, @channel)
    ChannelCtdChangeSet.create_job(ctd_logs, pool, @channel)

    if amount_logs.blank? and stop_sell_logs.blank? and min_stay_logs.blank? and cta_logs.blank? and ctd_logs.blank? and gta_travel_cta_logs.blank? and gta_travel_ctb_logs.blank?
      flash[:alert] = t('channel_rates.update.message.nothing_saved', :channel => @channel.name)
    else
      flash[:notice] = t('channel_rates.update.message.success', :channel => @channel.name)
    end
  end

  private

  # before running any channel rates operation
  # we must make sure that channel and pool is specified
  def check_requirement
    @channel = Channel.find_by_id(params[:channel_id])
    @pool = Pool.find_by_id(params[:pool_id])

    if @channel.blank? or @pool.blank?
      redirect_to root_path
    end
  end

  # handler to store channel rate
  def handle_amount(date_rate, rt, logs)
    if date_rate[1]["amount"]
      amount = date_rate[1]["amount"]
      existing_rate = ChannelRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date_rate[0], current_property.id, params[:pool_id], rt.id, @channel.id)

      # existing rate object exist, just do update if amount specified is not 0 or blank
      if existing_rate.blank?
        if amount.blank? or amount == 0
          # do nothing
        elsif amount.to_i > 0
          rate = ChannelRate.new
          rate.date = date_rate[0]
          rate.amount = amount
          rate.room_type_id = rt.id
          rate.property = current_property
          rate.pool = @pool
          rate.channel = @channel

          rate.save

          logs << create_channel_rate_log(rate)
        end
      else
        # existing rate object, just do update
        if amount.to_i >= 0 and (amount.to_i != existing_rate.amount.to_i)
          existing_rate.update_attribute(:amount, amount)
          
          logs << create_channel_rate_log(existing_rate)
        end
      end
    end
  end

  # create log entry for each rate change
  def create_channel_rate_log(channel_rate)
    ChannelRateLog.create(:channel_rate_id => channel_rate.id, :amount => channel_rate.amount)
  end

  # handler to store channel stop sell
  def handle_stop_sell(date_rate, rt, logs)
    if date_rate[1]['stop_sell']
      stop_sell = to_boolean(date_rate[1]['stop_sell'])
      existing_stop_sell = ChannelStopSell.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date_rate[0], current_property.id, params[:pool_id], rt.id, @channel.id)

      if existing_stop_sell.blank?
        if stop_sell.blank? or !stop_sell
          # do nothing
        else
          channel_stop_sell = ChannelStopSell.new
          channel_stop_sell.date = date_rate[0]
          channel_stop_sell.stop_sell = true
          channel_stop_sell.room_type_id = rt.id
          channel_stop_sell.property = current_property
          channel_stop_sell.pool = @pool
          channel_stop_sell.channel = @channel

          channel_stop_sell.save

          logs << create_channel_stop_sell_log(channel_stop_sell)
        end
      else
        # existing object exist, just do update
        if stop_sell != existing_stop_sell.stop_sell
          existing_stop_sell.update_attribute(:stop_sell, stop_sell)

          logs << create_channel_stop_sell_log(existing_stop_sell)
        end
      end
    end
  end

  # create log entry for each stop sell change
  def create_channel_stop_sell_log(channel_stop_sell)
    ChannelStopSellLog.create(:channel_stop_sell_id => channel_stop_sell.id, :stop_sell => channel_stop_sell.stop_sell)
  end

  def handle_min_stay(date_rate, rt, logs)
    if date_rate[1]["min_stay"]
      min_stay = date_rate[1]["min_stay"]
      existing_min_stay = ChannelMinStay.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date_rate[0], current_property.id, params[:pool_id], rt.id, @channel.id)

      if existing_min_stay.blank?
        if min_stay.blank? or min_stay == 0
          # do nothing
        elsif min_stay.to_i > 0
          channel_min_stay = ChannelMinStay.new
          channel_min_stay.date = date_rate[0]
          channel_min_stay.min_stay = min_stay
          channel_min_stay.room_type_id = rt.id
          channel_min_stay.property = current_property
          channel_min_stay.pool = @pool
          channel_min_stay.channel = @channel

          channel_min_stay.save

          logs << create_channel_min_stay_log(channel_min_stay)
        end
      else
        # existing object exist, just do update
        if min_stay.to_i >= 0 and (min_stay.to_i != existing_min_stay.min_stay.to_i)
          existing_min_stay.update_attribute(:min_stay, min_stay)

          logs << create_channel_min_stay_log(existing_min_stay)
        end
      end
    end
  end

  # create log entry for each min stay change
  def create_channel_min_stay_log(channel_min_stay)
    ChannelMinStayLog.create(:channel_min_stay_id => channel_min_stay.id, :min_stay => channel_min_stay.min_stay)
  end

  def handle_cta(date_rate, rt, logs)
    if date_rate[1]['cta']
      cta = to_boolean(date_rate[1]['cta'])
      existing_cta = ChannelCta.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date_rate[0], current_property.id, params[:pool_id], rt.id, @channel.id)

      if existing_cta.blank?
        if !cta
          # do nothing
        else
          channel_cta = ChannelCta.new
          channel_cta.date = date_rate[0]
          channel_cta.cta = true
          channel_cta.room_type_id = rt.id
          channel_cta.property = current_property
          channel_cta.pool = @pool
          channel_cta.channel = @channel

          channel_cta.save

          logs << create_channel_cta_log(channel_cta)
        end
      else
        # existing object exist, just do update
        if cta != existing_cta.cta
          existing_cta.update_attribute(:cta, cta)
          logs << create_channel_cta_log(existing_cta)
        end
      end
    end
  end

  # create log entry for each cta change
  def create_channel_cta_log(channel_cta)
    ChannelCtaLog.create(:channel_cta_id => channel_cta.id, :cta => channel_cta.cta)
  end

  def handle_ctd(date_rate, rt, logs)
    if date_rate[1]['ctd']
      ctd = to_boolean(date_rate[1]['ctd'])
      existing_ctd = ChannelCtd.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date_rate[0], current_property.id, params[:pool_id], rt.id, @channel.id)

      if existing_ctd.blank?
        if ctd.blank? or !ctd
          # do nothing
        else
          channel_ctd = ChannelCtd.new
          channel_ctd.date = date_rate[0]
          channel_ctd.ctd = true
          channel_ctd.room_type_id = rt.id
          channel_ctd.property = current_property
          channel_ctd.pool = @pool
          channel_ctd.channel = @channel

          channel_ctd.save

          logs << create_channel_ctd_log(channel_ctd)
        end
      else
        # existing object exist, just do update
        if ctd != existing_ctd.ctd
          existing_ctd.update_attribute(:ctd, ctd)

          logs << create_channel_ctd_log(existing_ctd)
        end
      end
    end
  end

  # create log entry for each ctd change
  def create_channel_ctd_log(channel_ctd)
    ChannelCtdLog.create(:channel_ctd_id => channel_ctd.id, :ctd => channel_ctd.ctd)
  end

  def handle_gta_travel_channel_cta(date_rate, logs)
    if date_rate[1]
      cta = to_boolean(date_rate[1])
      existing_cta = GtaTravelChannelCta.find_by_date_and_property_id_and_pool_id_and_channel_id(date_rate[0], current_property.id, params[:pool_id], @channel.id)

      if existing_cta.blank?
        if !cta
          # do nothing
        else
          channel_cta = GtaTravelChannelCta.new
          channel_cta.date = date_rate[0]
          channel_cta.cta = true
          channel_cta.property = current_property
          channel_cta.pool = @pool
          channel_cta.channel = @channel

          channel_cta.save

          logs << create_gta_travel_channel_cta_log(channel_cta)
        end
      else
        # existing object exist, just do update
        if cta != existing_cta.cta
          existing_cta.update_attribute(:cta, cta)
          logs << create_gta_travel_channel_cta_log(existing_cta)
        end
      end
    end
  end

  # create log entry for each cta change
  def create_gta_travel_channel_cta_log(channel_cta)
    GtaTravelChannelCtaLog.create(:gta_travel_channel_cta_id => channel_cta.id, :cta => channel_cta.cta)
  end

  def handle_gta_travel_channel_ctb(date_rate, logs)
    if date_rate[1]
      ctb = to_boolean(date_rate[1])
      existing_ctb = GtaTravelChannelCtb.find_by_date_and_property_id_and_pool_id_and_channel_id(date_rate[0], current_property.id, params[:pool_id], @channel.id)

      if existing_ctb.blank?
        if !ctb
          # do nothing
        else
          channel_ctb = GtaTravelChannelCtb.new
          channel_ctb.date = date_rate[0]
          channel_ctb.ctb = true
          channel_ctb.property = current_property
          channel_ctb.pool = @pool
          channel_ctb.channel = @channel

          channel_ctb.save

          logs << create_gta_travel_channel_ctb_log(channel_ctb)
        end
      else
        # existing object exist, just do update
        if ctb != existing_ctb.ctb
          existing_ctb.update_attribute(:ctb, ctb)
          logs << create_gta_travel_channel_ctb_log(existing_ctb)
        end
      end
    end
  end

  # create log entry for each ctb change
  def create_gta_travel_channel_ctb_log(channel_ctb)
    GtaTravelChannelCtbLog.create(:gta_travel_channel_ctb_id => channel_ctb.id, :ctb => channel_ctb.ctb)
  end

end
