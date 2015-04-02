# controller to handle master rate
class RoomTypeMasterRateChannelMappingsController < ApplicationController

  before_filter :member_authenticate_and_property_selected
  before_filter :set_pool

  # new channel master rate form
  def new
    @room_type_master_rate_channel_mapping = RoomTypeMasterRateChannelMapping.new
    @room_type_master_rate_channel_mapping.channel = Channel.find_by_id(params[:channel_id])
    @room_type_master_rate_channel_mapping.room_type = RoomType.find_by_id(params[:room_type_id])
  end

  # edit channel master rate
  def edit
    @room_type_master_rate_channel_mapping = RoomTypeMasterRateChannelMapping.find(params[:id])
  end

  # create the channel master rate
  def create
    @room_type_master_rate_channel_mapping = RoomTypeMasterRateChannelMapping.new(params[:room_type_master_rate_channel_mapping])
    method = params[:room_type_master_rate_channel_mapping][:method]

    # handle method selected (percentage or amount)
    if method == RoomTypeMasterRateChannelMapping::PERCENTAGE
      @room_type_master_rate_channel_mapping.method = RoomTypeMasterRateChannelMapping::PERCENTAGE
      @room_type_master_rate_channel_mapping.percentage = params[:room_type_master_rate_channel_mapping][:percentage]
      @room_type_master_rate_channel_mapping.value = nil
    elsif method == RoomTypeMasterRateChannelMapping::AMOUNT
      @room_type_master_rate_channel_mapping.method = RoomTypeMasterRateChannelMapping::AMOUNT
      @room_type_master_rate_channel_mapping.percentage = nil
      @room_type_master_rate_channel_mapping.value = params[:room_type_master_rate_channel_mapping][:value]
    end

    # after save then run rate sync
    if @room_type_master_rate_channel_mapping.save
      @room_type_master_rate_channel_mapping.sync_rate
      redirect_to room_type_master_rate_mappings_path(:pool_id => @room_type_master_rate_channel_mapping.master_rate_mapping.pool.id)
    else
      put_model_errors_to_flash(@room_type_master_rate_channel_mapping.errors)
      render 'new'
    end

  end

  def update
    @room_type_master_rate_channel_mapping = RoomTypeMasterRateChannelMapping.find(params[:id])
    @room_type_master_rate_channel_mapping.master_rate_mapping = RoomTypeMasterRateMapping.find_by_id(params[:room_type_master_rate_channel_mapping][:room_type_master_rate_mapping_id])
    method = params[:room_type_master_rate_channel_mapping][:method]

    if method == RoomTypeMasterRateChannelMapping::PERCENTAGE
      @room_type_master_rate_channel_mapping.method = RoomTypeMasterRateChannelMapping::PERCENTAGE
      @room_type_master_rate_channel_mapping.percentage = params[:room_type_master_rate_channel_mapping][:percentage]
      @room_type_master_rate_channel_mapping.value = nil
    elsif method == RoomTypeMasterRateChannelMapping::AMOUNT
      @room_type_master_rate_channel_mapping.method = RoomTypeMasterRateChannelMapping::AMOUNT
      @room_type_master_rate_channel_mapping.percentage = nil
      @room_type_master_rate_channel_mapping.value = params[:room_type_master_rate_channel_mapping][:value]
    end

    if @room_type_master_rate_channel_mapping.save
      @room_type_master_rate_channel_mapping.sync_rate
      redirect_to room_type_master_rate_mappings_path(:pool_id => @room_type_master_rate_channel_mapping.master_rate_mapping.pool.id)
    else
      put_model_errors_to_flash(@room_type_master_rate_channel_mapping.errors)
      render 'edit'
    end
    
  end

  def delete
    @room_type_master_rate_channel_mapping = RoomTypeMasterRateChannelMapping.find(params[:id])
    flash[:notice] = t('room_type_master_rate_channel_mappings.toggle.message.disabled')
    @room_type_master_rate_channel_mapping.deleted = true
    copy_master_rate_to_channel_rate(@room_type_master_rate_channel_mapping)
    @room_type_master_rate_channel_mapping.save
    
    redirect_to room_type_master_rate_mappings_path(:pool_id => @room_type_master_rate_channel_mapping.master_rate_mapping.pool.id)
  end

  private

  def set_pool
    redirect_to master_rate_pool_selection_path if params[:pool_id].blank?
    @pool = Pool.find(params[:pool_id])
  end

  def copy_master_rate_to_channel_rate(mapping)
    master_room_type = mapping.master_rate_mapping.room_type

    loop_date = DateTime.now.in_time_zone.beginning_of_day
    while loop_date <= Constant.maximum_end_date
      master_rate = MasterRate.find_by_date_and_room_type_id_and_pool_id(loop_date, master_room_type.id, mapping.master_rate_mapping.pool.id)

      amount_to_use = master_rate.blank? ? 0 : master_rate.amount
      channel_rate = ChannelRate.find_by_date_and_room_type_id_and_pool_id_and_channel_id(loop_date, mapping.room_type_id, mapping.master_rate_mapping.pool.id, mapping.channel.id)

      if channel_rate.blank?
        channel_rate = ChannelRate.new
        channel_rate.channel = mapping.channel
        channel_rate.date = loop_date
        channel_rate.amount = mapping.apply_value(amount_to_use)
        channel_rate.room_type_id = mapping.room_type_id
        channel_rate.property = master_room_type.property
        channel_rate.pool = mapping.master_rate_mapping.pool
        channel_rate.save
      else
        channel_rate.update_attribute(:amount, mapping.apply_value(amount_to_use))
      end

      loop_date = loop_date + 1.day
    end
  end
  
end
