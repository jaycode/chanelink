# copy tool controller
class CopyToolController < ApplicationController

  load_and_authorize_resource

  before_filter :member_authenticate_and_property_selected
  before_filter :set_pool

  # render the copy tool user interface
  def tool

    # prepare the object and initiate the value from prev params if needed
    @copy_tool = CopyTool.new
    @restriction_from = nil
    @restriction_to = nil
    @copy_tool.value_type = params[:value_type] if params[:value_type]
    @copy_tool.channel_id_from = params[:channel_id_from] ? params[:channel_id_from] : Channel.first.id
    @copy_tool.channel_id_to = params[:channel_id_to] ? params[:channel_id_to] : Channel.first.id

    @copy_tool.room_id_from = params[:room_id_from] ? params[:room_id_from] : nil
    @copy_tool.room_id_to = params[:room_id_to] ? params[:room_id_to] : nil

    # load the cta ctd restriction
    if params[:value_type] == CopyTool::VALUE_CTA
      @restriction_from = (Constant::SUPPORT_CTA.collect &:id) + (Constant::SUPPORT_GTA_TRAVEL_CHANNEL_CTA.collect &:id)
      @restriction_to = Constant::SUPPORT_CTA.collect &:id
    elsif params[:value_type] == CopyTool::VALUE_CTD
      @restriction_from = Constant::SUPPORT_CTD.collect &:id
      @restriction_to = Constant::SUPPORT_CTD.collect &:id
    elsif params[:value_type] == CopyTool::VALUE_CTB
      @restriction_from = Constant::SUPPORT_GTA_TRAVEL_CHANNEL_CTB.collect &:id
      @restriction_to = Constant::SUPPORT_GTA_TRAVEL_CHANNEL_CTB.collect &:id
    end
  end

  # handle submitted form of copy value
  def submit
    @copy_tool = CopyTool.new(params[:ct])
    @copy_tool.property = current_property
    if @copy_tool.valid?
      @copy_tool.do_update
      flash[:notice] = t('copy_tool.message.success')
      redirect_to copy_tool_path
    else
      put_model_errors_to_flash(@copy_tool.errors)
      render 'tool'
    end
  end

  private

  # handle pool automatically if only one exist
  def set_pool
    if params[:pool_id] and params[:pool_id] != 'undefined'
      @pool = current_property.pools.find(params[:pool_id])
    else
      @pool = current_property.pools.first
    end
  end

end
