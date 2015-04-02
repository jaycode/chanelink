# handles all pool related
class PoolsController < ApplicationController

  before_filter :member_authenticate_and_property_selected

  # list all pool
  def index
    @pools = current_property.pools
  end

  # handle new pool creation
  def create
    init_variables_from_sessions
    if params[:back_button]
      redirect_to new_wizard_details_pools_path
    else
      if @pool.valid?
        @pool.save

        # handle channels assign to this new pool
        disabled_channels = params[:availability] == Constant::POOL_DISABLE_CHANNELS ? true : false
        unless @pool.assigned_channels.blank?
          channel_ids = @pool.assigned_channels

          # get each channel assigned to this pool
          channel_ids.each do |channel_id|
            pc = PropertyChannel.find_by_property_id_and_channel_id(current_property.id, channel_id)
            pc.previous_pool_id = pc.pool_id
            # set channel to the new pool, if disabled then do not run sync all data
            if disabled_channels
              pc.pool_id = @pool.id
              pc.disabled = true
              pc.save
              pc.migrate_room_data_to_new_pool
              pc.delete_all_master_rate_mapping
            else
              pc.pool_id = @pool.id
              pc.save
              pc.migrate_room_data_to_new_pool
              pc.sync_all_data
              pc.delete_all_master_rate_mapping
            end
          end
        end

        redirect_to pools_path
      else
        put_model_errors_to_flash(@pool.errors)
        redirect_to new_wizard_details_pools_path
      end
    end
  end

  # form to create new pool
  def new
    session[:pool_params] = {}
    redirect_to new_wizard_details_pools_path
  end

  # form to create new pool - channels step
  def new_wizard_details
    @pool = Pool.new(session[:pool_params])
  end

  # form to create new pool - Step confirmation
  def new_wizard_confirmation

    init_variables_from_sessions

    if @pool.valid?
      # do nothing
    else
      put_model_errors_to_flash(@pool.errors, 'redirect')
      redirect_to new_wizard_details_pools_path
    end
  end

  # edit pool
  def edit
    session[:pool_params] = {}
    @pool = Pool.find(params[:id])
    redirect_to edit_wizard_details_pool_path(@pool)
  end

  # edit pool - channels step
  def edit_wizard_details
    @pool = Pool.find(params[:id])
    @pool.attributes = session[:pool_params]
  end

  # edit pool- confirmation step
  def edit_wizard_confirmation
    init_variables_from_sessions_for_edit

    if @pool.valid?
      # do nothing
    else
      put_model_errors_to_flash(@pool.errors, 'redirect')
      redirect_to edit_wizard_details_pool_path(@pool)
    end
  end

  # handle pool update
  def update
    init_variables_from_sessions_for_edit

    if params[:back_button]
      redirect_to edit_wizard_details_pool_path(@pool)
    else
      if @pool.valid?
        @pool.save

        # handle channels assign to this new pool
        disabled_channels = params[:availability] == Constant::POOL_DISABLE_CHANNELS ? true : false
        unless @pool.assigned_channels.blank?
          channel_ids = @pool.assigned_channels
          channel_ids.each do |channel_id|
            pc = PropertyChannel.find_by_property_id_and_channel_id(current_property.id, channel_id)
            pc.previous_pool_id = pc.pool_id
            # set channel to the new pool, runc sync all data if not disabled
            if disabled_channels
              pc.update_attributes(:pool_id => @pool.id, :disabled => true)
              pc.migrate_room_data_to_new_pool
              pc.delete_all_master_rate_mapping
            else
              pc.update_attribute(:pool_id, @pool.id)
              pc.migrate_room_data_to_new_pool
              pc.sync_all_data
              pc.delete_all_master_rate_mapping
            end
          end
        end

        redirect_to pools_path
      else
        put_model_errors_to_flash(@pool.errors)
        redirect_to new_wizard_details_pools_path
      end
    end
  end

  # delete pool
  def delete
    @pool = Pool.find(params[:id])
    # only allow if this is not the last pool
    if @pool.property.pools.count > 1
      @pool.update_attribute(:deleted, true)
      flash[:notice] = t("pools.delete.message.success")
    else
      flash[:alert] = t("pools.delete.message.last_one")
    end
    redirect_to pools_path
  end

  private

  # helper for pool create wizard
  def init_variables_from_sessions
    session[:pool_params].deep_merge!(params[:pool]) if params[:pool]
    if params[:pool] and params[:pool][:assigned_channels].blank?
      session[:pool_params].delete('assigned_channels')
    end
    @pool = current_property.pools.new(session[:pool_params])
  end

  # helper for pool update wizard
  def init_variables_from_sessions_for_edit
    session[:pool_params].deep_merge!(params[:pool]) if params[:pool]
    if params[:pool] and params[:pool][:assigned_channels].blank?
      session[:pool_params].delete('assigned_channels')
    end
    @pool = current_property.pools.find(params[:id])
    @pool.attributes = session[:pool_params]
  end

end
