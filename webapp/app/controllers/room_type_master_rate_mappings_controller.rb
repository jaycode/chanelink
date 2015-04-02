# controller for master rate mapping
class RoomTypeMasterRateMappingsController < ApplicationController

  before_filter :member_authenticate_and_property_selected
  before_filter :set_pool

  # master rate mapping new form
  def new
    @room_type_master_rate_mapping = RoomTypeMasterRateMapping.new
    @room_type_master_rate_mapping.pool = @pool

    # remove room type that already mapped
    @room_types = Array.new
    current_property.room_types.each do |rt|
      @room_types << [rt.name, rt.id] if RoomTypeMasterRateMapping.find_by_room_type_id_and_pool_id(rt.id, @pool.id).blank?
    end
  end

  # create new master rate mapping
  def create
    if params[:room_type_ids] and params[:pool_id]
      # handle multiple room create, loop by room type
      params[:room_type_ids].each do |room_type_id|
        rtm = RoomTypeMasterRateMapping.new
        rtm.room_type_id = room_type_id
        rtm.pool_id = params[:pool_id]

        # after create then populate rate
        if rtm.valid?
          rtm.save
          populate_with_rack_rate(rtm)
          flash[:notice] = t('room_type_master_rate_mappings.create.message.success')
        else
          put_model_errors_to_flash(rtm.errors, 'redirect')
        end
      end
    end
    redirect_to room_type_master_rate_mappings_path(:pool_id => params[:pool_id])
  end

  # delete master rate mapping
  def delete
    if params[:id] and params[:pool_id]
      RoomTypeMasterRateMapping.find_by_id_and_pool_id(params[:id], params[:pool_id]).update_attribute(:deleted, true)
      flash[:notice] = t('room_type_master_rate_mappings.delete.message.success')
    end
    redirect_to room_type_master_rate_mappings_path(:pool_id => params[:pool_id])
  end

  def pool_selection
    if current_property.pools.size == 1
      pool = current_property.pools.first
      redirect_to room_type_master_rate_mappings_path(:pool_id => pool.id)
    end
  end

  # automatically select pool if it's only one pool
  def set_pool
    if current_property.single_pool? or !params[:pool_id]
      @pool = current_property.pools.first
    else
      @pool = current_property.pools.find(params[:pool_id])
    end
  end

  private

  # populate next 400 days with master rate room type rack rate
  def populate_with_rack_rate(rtm)
    rate_to_use = rtm.room_type.basic_rack_rate
    loop_date = DateTime.now.in_time_zone.beginning_of_day
    while loop_date <= Constant.maximum_end_date
      existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(loop_date, current_property.id, rtm.pool_id, rtm.room_type.id)

      if existing_rate.blank?
        rate = MasterRate.new
        rate.date = loop_date
        rate.amount = rate_to_use
        rate.room_type_id = rtm.room_type.id
        rate.property = current_property
        rate.pool_id = rtm.pool_id

        rate.save
      else
        existing_rate.update_attribute(:amount, rate_to_use)
      end
      loop_date = loop_date + 1.day
    end
  end
  
end
