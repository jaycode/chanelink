require 'net/https'

# admin module for room type mapping
class Admin::RoomTypeChannelMappingsController < Admin::AdminController

  before_filter :user_authenticate_and_account_property_selected

  def index
    @room_type = RoomType.find(params[:room_type_id])
  end

  # new room type mapping
  def new
    session[:room_type_channel_mapping_params] = {}
    session[:room_type_channel_mapping_params][:channel_id] = Channel.find(params[:channel_id]).id
    session[:room_type_channel_mapping_params][:room_type_id] = RoomType.find(params[:room_type_id]).id

    session[:room_type_master_rate_channel_mapping_params] = {}
    
    redirect_to new_wizard_channel_room_admin_room_type_channel_mappings_path
  end

  # new room type mapping - step 1
  def new_wizard_channel_room
    init_variables_from_sessions
    get_channel_room_types
  end

  # new room type mapping - step 2
  def new_wizard_channel_settings
    init_variables_from_sessions
    set_extra_room_type_info
    
    @room_type_channel_mapping.skip_extra_validation = true
    @room_type_channel_mapping.skip_rate_configuration = true

    if @room_type_channel_mapping.valid?
      # do nothing
    else
      put_model_errors_to_flash(@room_type_channel_mapping.errors, 'redirect')
      redirect_to new_wizard_channel_room_admin_room_type_channel_mappings_path
    end
  end

  # new room type mapping - step 3
  def new_wizard_rate
    init_variables_from_sessions

    if params[:back_button]
      redirect_to new_wizard_channel_room_admin_room_type_channel_mappings_path
    else
      @room_type_channel_mapping.skip_rate_configuration = true

      if @room_type_channel_mapping.valid?
        # do nothing
      else
        put_model_errors_to_flash(@room_type_channel_mapping.errors, 'redirect')
        redirect_to new_wizard_channel_settings_admin_room_type_channel_mappings_path
      end
    end
  end

  # new room type mapping - step 4
  def new_wizard_confirm
    init_variables_from_sessions

    if params[:back_button]
      redirect_to new_wizard_channel_settings_admin_room_type_channel_mappings_path
    else

      if @room_type_channel_mapping.valid? and (!@room_type_channel_mapping.is_configuration_master_rate? or @room_type_master_rate_channel_mapping.valid?)
        # do nothing
        @room_type_channel_mapping.disabled = true
      else
        if @room_type_channel_mapping.is_configuration_master_rate?
          put_model_errors_to_flash(@room_type_master_rate_channel_mapping.errors, 'redirect')
        else
          put_model_errors_to_flash(@room_type_channel_mapping.errors, 'redirect')
        end
        redirect_to new_wizard_rate_admin_room_type_channel_mappings_path
      end
    end
  end

  # create room type mapping - last step
  def create
    init_variables_from_sessions
    
    if params[:back_button]
      redirect_to new_wizard_rate_admin_room_type_channel_mappings_path
    else
      if @room_type_channel_mapping.valid? and (!@room_type_channel_mapping.is_configuration_master_rate? or @room_type_master_rate_channel_mapping.valid?)
        @room_type_channel_mapping.disabled = @room_type_channel_mapping.enabled == '0' ? true : false
        @room_type_channel_mapping.save

        # if using master rate, then save the master rate object
        if @room_type_channel_mapping.is_configuration_master_rate?
          @room_type_master_rate_channel_mapping.save
        end

        # sync all data
        @room_type_channel_mapping.set_rate
        @room_type_channel_mapping.sync_availability

        flash[:notice] = t('room_type_channel_mappings.create.message.success')
        pc = PropertyChannel.find_by_property_id_and_channel_id(current_admin_property.id, @room_type_channel_mapping.channel.id)
        
        redirect_to admin_room_type_channel_mappings_path(:room_type_id => @room_type_channel_mapping.room_type.id)
      else
        put_model_errors_to_flash(@room_type_channel_mapping.errors)
        redirect_to new_wizard_channel_room_admin_room_type_channel_mappings_path
      end
    end
  end

  # edit room type channel mapping
  def edit
    @room_type_channel_mapping = RoomTypeChannelMapping.find(params[:id])
    @channel = @room_type_channel_mapping.channel

    get_channel_room_types

    @logger = Logger.new("#{Rails.root}/log/custom.log")
    @logger.error("edit top")
    all_channel_room_types = Array.new
    begin
      # get channel/OTA room type data
      @logger.error("before room types")
      all_channel_room_types = @channel.room_type_fetcher.retrieve(current_admin_property, false)
    rescue Exception => e
      @logger.error("after room types")
      flash[:notice] = t('room_type_channel_mappings.edit.message.timeout', :channel => @channel.channel.name)
    end

    all_channel_room_types.each do |crt|
      if crt.id == @room_type_channel_mapping.channel_room_type_id
        @channel_room_types.insert(0, ["#{crt.name} - #{crt.id}", crt.id])
      end
    end
  end

  # get channel/OTA room type data
  def get_channel_room_types
    room_types = Array.new
    
    begin
      room_types = @channel.room_type_fetcher.retrieve(current_admin_property, true)
    rescue Exception
      flash[:notice] = t('room_type_channel_mappings.edit.message.timeout', :channel => @channel.name)
    end

    @channel_room_types = Array.new
    
    room_types.each do |crt|
      @channel_room_types << ["#{crt.name} - #{crt.id}", crt.id]
    end

    @room_types = Array.new
    current_admin_property.room_types.each do |rt|
      @room_types << [rt.name, rt.id] if RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(rt.id, @channel.id).blank?
    end
  end

  # update room type mapping
  def update
    @room_type_channel_mapping = RoomTypeChannelMapping.find(params[:id])
    @room_type_channel_mapping.skip_extra_validation = true
    @room_type_channel_mapping.skip_rate_configuration = true

    old_disabled = @room_type_channel_mapping.disabled?
    
    if @room_type_channel_mapping.update_attributes(params[:room_type_channel_mapping])
      @room_type_channel_mapping.skip_rate_configuration = false
      @room_type_channel_mapping.set_rate

      if old_disabled != @room_type_channel_mapping.disabled and !@room_type_channel_mapping.disabled
        @room_type_channel_mapping.sync_all_data
        puts 'enabled'
      end

      flash[:notice] = t('room_type_channel_mappings.update.message.success')
      pc = PropertyChannel.find_by_property_id_and_channel_id(current_admin_property.id, @room_type_channel_mapping.channel.id)

      redirect_to admin_room_type_channel_mappings_path(:room_type_id => @room_type_channel_mapping.room_type.id)
    else
      put_model_errors_to_flash(@room_type_channel_mapping.errors)
      render 'edit'
    end
  end

  # delete room type mapping
  def delete
    @room_type_channel_mapping = RoomTypeChannelMapping.find(params[:id])
    @room_type_channel_mapping.delete

    flash[:notice] = t('room_type_channel_mappings.delete.message.success')
    pc = PropertyChannel.find_by_property_id_and_channel_id(current_admin_property.id, @room_type_channel_mapping.channel.id)
    redirect_to admin_room_type_channel_mappings_path(:room_type_id => @room_type_channel_mapping.room_type.id)
  end

  private

  # helper for wizard, set data in session
  def init_variables_from_sessions
    session[:room_type_channel_mapping_params].deep_merge!(params[:room_type_channel_mapping]) if params[:room_type_channel_mapping]
    session[:room_type_master_rate_channel_mapping_params].deep_merge!(params[:room_type_master_rate_channel_mapping]) if params[:room_type_master_rate_channel_mapping]

    @room_type_channel_mapping = RoomTypeChannelMapping.new(session[:room_type_channel_mapping_params])
    @channel = Channel.find(@room_type_channel_mapping.channel_id)
    @room_type = RoomType.find(@room_type_channel_mapping.room_type_id)

    @room_type_master_rate_channel_mapping = RoomTypeMasterRateChannelMapping.new(session[:room_type_master_rate_channel_mapping_params])
    @room_type_master_rate_channel_mapping.channel = @channel
    @room_type_master_rate_channel_mapping.room_type = @room_type
  end

  # helper to set channel/OTA room type info
  def set_extra_room_type_info
    begin
      if @room_type_channel_mapping.channel_id == AgodaChannel.first.id
        art = AgodaChannel.first.room_type_fetcher.retrieve(current_admin_property, false)
        art.each do |rt|
          if @room_type_channel_mapping.agoda_room_type_id == rt.id
            @room_type_channel_mapping.agoda_room_type_name = rt.name
            session[:room_type_channel_mapping_params].deep_merge!(@room_type_channel_mapping.attributes)
          end
        end
      elsif @room_type_channel_mapping.channel_id == ExpediaChannel.first.id
        ert = ExpediaChannel.first.room_type_fetcher.retrieve(current_admin_property, false)
        ert.each do |rt|
          if @room_type_channel_mapping.expedia_room_type_id == rt.id
            @room_type_channel_mapping.expedia_room_type_name = rt.name
            @room_type_channel_mapping.expedia_rate_plan_id = rt.rate_plan_id
            session[:room_type_channel_mapping_params].deep_merge!(@room_type_channel_mapping.attributes)
          end
        end
      elsif @room_type_channel_mapping.channel_id == BookingcomChannel.first.id
        ert = BookingcomChannel.first.room_type_fetcher.retrieve(current_admin_property, false)
        ert.each do |rt|
          if @room_type_channel_mapping.bookingcom_room_type_id == rt.id
            @room_type_channel_mapping.bookingcom_room_type_name = rt.name
            @room_type_channel_mapping.bookingcom_rate_plan_id = rt.rate_plan_id
            session[:room_type_channel_mapping_params].deep_merge!(@room_type_channel_mapping.attributes)
          end
        end
      # GTA travel room type
      elsif @room_type_channel_mapping.channel_id == GtaTravelChannel.first.id
        ert = GtaTravelChannel.first.room_type_fetcher.retrieve(current_property, false)
        ert.each do |rt|
          if @room_type_channel_mapping.gta_travel_room_type_id == rt.id
            @room_type_channel_mapping.gta_travel_room_type_name = rt.name
            @room_type_channel_mapping.gta_travel_rate_basis = rt.rate_basis
            @room_type_channel_mapping.gta_travel_max_occupancy = rt.max_occupancy
            session[:room_type_channel_mapping_params].deep_merge!(@room_type_channel_mapping.attributes) unless skip_session
          end
        end
      # Ctrip travel room type
      elsif @room_type_channel_mapping.channel_id == CtripChannel.first.id
        ert = CtripChannel.first.room_type_fetcher.retrieve(current_property, false)
        ert.each do |rt|
          if @room_type_channel_mapping.settings(:ctrip_rate_plan_code) == rt.rate_plan_code and @room_type_channel_mapping.settings(:ctrip_rate_plan_category) == rt.rate_plan_category
            @room_type_channel_mapping.settings = {
              :ctrip_room_type_name => rt.name,
              :ctrip_rate_plan_code => rt.rate_plan_code
              :ctrip_rate_plan_category => rt.rate_plan_category
            }
            session[:room_type_channel_mapping_params].deep_merge!(@room_type_channel_mapping.attributes) unless skip_session
          end
        end
      end
    rescue Exception
      flash[:notice] = t('room_type_channel_mappings.edit.message.timeout', :channel => @room_type_channel_mapping.channel.name)
    end
  end

  # not used
  def handle_rate_after_create
    if @room_type_channel_mapping.is_configuration_master_rate?

    else
      rate_to_use = @room_type_channel_mapping.is_configuration_new_rate? ? @room_type_channel_mapping.new_rate : @room_type_channel_mapping.room_type.basic_rack_rate
      puts rate_to_use
      RateUtils.delay.populate_rate_until_day_limit(rate_to_use, @room_type_channel_mapping.room_type, @room_type_channel_mapping.channel, PropertyChannel.find_by_channel_id(@channel.id).pool, current_admin_property)
    end
  end
  
end
