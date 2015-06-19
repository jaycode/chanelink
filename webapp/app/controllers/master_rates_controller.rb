# controllar to handle master rate changes from inventory grid
class MasterRatesController < ApplicationController

  before_filter :member_authenticate_and_property_selected

  # handle form submission from inventory grid - master rate
  def update
    @pool = Pool.find(params[:pool_id])
    if validate_master_rates
      do_update
      redirect_to grid_inventories_path(:pool_id => @pool.id, :master_rates_start => params[:master_rates_start])
    else
      redirect_to grid_inventories_path(:pool_id => @pool.id, :master_rates_start => params[:master_rates_start]), :flash => {:master_rates => params}
    end
  end

  def do_update
    logs = Array.new
    current_property.room_types.each do |rt|
      if params["#{rt.id}"]
        current_property.account.rate_types.each do |rate_type|
          if params["#{rt.id}"]["#{rate_type.id}"]
            params["#{rt.id}"]["#{rate_type.id}"].each do |date_rate|
              handle_amount(date_rate, rt, rate_type, logs)
            end
          end
        end
      end
    end
    MasterRateChangeSet.create_job(logs, @pool)

    if logs.blank?
      flash[:alert] = t('master_rates.update.message.nothing_saved')
    else
      flash[:notice] = t('master_rates.update.message.success')
    end
  end

  # validate rates given
  def validate_master_rates
    result = true
    errors = Array.new

    current_property.room_types.each do |rt|
      if params["#{rt.id}"]
        current_property.account.rate_types.each do |rate_type|
          if params["#{rt.id}"]["#{rate_type.id}"]
            params["#{rt.id}"]["#{rate_type.id}"].each do |date_rate|
              if date_rate[1]["amount"]
                amount = date_rate[1]["amount"]
                # rates must be positive integer and greater then minimum
                if !(amount =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/)
                  errors << t('master_rates.validate.error_not_a_number', :room_type => rt.name, :rate_type => rate_type.name, :date => date_rate[0])
                elsif amount.to_f < 0
                  errors << t('master_rates.validate.error_negative_number', :room_type => rt.name, :rate_type => rate_type.name, :date => date_rate[0])
                elsif amount.to_f < rt.final_minimum_rate
                  errors << t('master_rates.validate.error_less_than_minimum', :room_type => rt.name, :rate_type => rate_type.name, :date => date_rate[0], :minimum => rt.final_minimum_rate)
                end
              end
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

  private

  # handle storing of the master rate
  def handle_amount(date_rate, rt, rate_type, logs)
    
    if date_rate[1]["amount"]
      amount = date_rate[1]["amount"]
      existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_rate_type_id(
        date_rate[0], current_property.id, params[:pool_id], rt.id, rate_type.id)

      # no existing, create new master rate object
      if existing_rate.blank?
        if amount.blank? or amount == 0
          # do nothing
        elsif amount.to_f > 0
          rate = MasterRate.new
          rate.date = date_rate[0]
          rate.amount = amount
          rate.room_type_id = rt.id
          rate.rate_type_id = rate_type.id
          rate.property = current_property
          rate.pool_id = @pool.id

          rate.save
          logs << create_master_rate_log(rate)
        end
      else
        # have existing? then just do update
        if amount.to_f >= 0 and (amount.to_f != existing_rate.amount.to_f)
          existing_rate.update_attribute(:amount, amount)
          logs << create_master_rate_log(existing_rate)
        end
      end
    end
  end

  # create log/version for each master rate changes
  def create_master_rate_log(master_rate)
    MasterRateLog.create(:master_rate_id => master_rate.id, :amount => master_rate.amount)
  end

end
