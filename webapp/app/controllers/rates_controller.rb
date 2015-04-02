# module to handle rates change
# old module, currently not used
class RatesController < ApplicationController

  def update
    current_property.room_types.each do |rt|
      params["#{rt.id}"].each do |date_rate|
        handle_amount(date_rate, rt)
        handle_stop_sell(date_rate, rt)
      end
    end
    redirect_to grid_inventories_path(params[:pool_id])
  end

  private
  
  def handle_amount(date_rate, rt)
    if date_rate[1]["amount"]
      amount = date_rate[1]["amount"]
      existing_rate = Rate.find_by_date_and_property_id_and_pool_id_and_room_type_id(date_rate[0], current_property.id, params[:pool_id], rt.id)

      if existing_rate.blank?
        if amount.blank? or amount == 0
          # do nothing
        elsif amount.to_i > 0
          rate = Rate.new
          rate.date = date_rate[0]
          rate.amount = amount
          rate.room_type_id = rt.id
          rate.property = current_property
          rate.pool_id = params[:pool_id]

          rate.save
        end
      else
        if amount.to_i >= 0 and (amount.to_i != existing_rate.amount.to_i)
          existing_rate.update_attribute(:amount, amount)
        end
      end
    end
  end

  def handle_stop_sell(date_rate, rt)
    if date_rate[1]['stop_sell']
      stop_sell = date_rate[1]['stop_sell']
      existing_rate = Rate.find_by_date_and_property_id_and_pool_id_and_room_type_id(date_rate[0], current_property.id, params[:pool_id], rt.id)

      if existing_rate.blank?
        if stop_sell.blank? or !stop_sell
          # do nothing
        else
          rate = Rate.new
          rate.date = date_rate[0]
          rate.stop_sell = true
          rate.room_type_id = rt.id
          rate.property = current_property
          rate.pool_id = params[:pool_id]

          rate.save
        end
      else
        if stop_sell != existing_rate.stop_sell
          existing_rate.update_attribute(:stop_sell, true)
        end
      end
    end
  end

end
