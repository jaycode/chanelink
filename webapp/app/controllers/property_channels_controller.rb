# controller for property mapped to a channel
class PropertyChannelsController < ApplicationController

  before_filter :member_authenticate_and_property_selected

  load_and_authorize_resource

  # list channel mapped to the current property
  def index
    if params[:pool_id]
      pool = current_property.pools.find(params[:pool_id])
      @property_channels = pool.channels
    else
      @property_channels = current_property.pools.first.channels
    end
  end

  # new channel wizard
  def new
    session[:property_channel_params] = {}
    session[:currency_conversion_params] = {}
    redirect_to new_wizard_selection_property_channels_path
  end

  # new channel wizard - step 1
  def new_wizard_selection
    init_variables_from_sessions
  end

  # new channel wizard - step 2
  def new_wizard_setting
    init_variables_from_sessions
    
    @property_channel.skip_channel_specific = true
    @property_channel.skip_rate_conversion_multiplier = true
    
    if @property_channel.valid?
      # do nothing
    else
      put_model_errors_to_flash(@property_channel.errors, 'redirect')
      redirect_to new_wizard_selection_property_channels_path
    end
  end

  # new channel wizard - step 3
  def new_wizard_conversion
    init_variables_from_sessions
    @property_channel.skip_rate_conversion_multiplier = true

    if params[:back_button]
      redirect_to new_wizard_selection_property_channels_path
    else
      if @property_channel.valid?
        # do nothing
      else
        put_model_errors_to_flash(@property_channel.errors, 'redirect')
        redirect_to new_wizard_setting_property_channels_path
      end
    end
  end

  # new channel wizard - step 4
  def new_wizard_rate_multiplier
    init_variables_from_sessions

    if params[:back_button]
      redirect_to new_wizard_setting_property_channels_path
    else
      if @currency_conversion.valid? or @currency_conversion.to_currency.blank?
        # do nothing
      else
        put_model_errors_to_flash(@currency_conversion.errors, 'redirect')
        redirect_to new_wizard_conversion_property_channels_path
      end
    end
  end

  # new channel wizard - step 5
  def new_wizard_confirm
    init_variables_from_sessions

    if params[:back_button]
      redirect_to new_wizard_conversion_property_channels_path
    else
      if @property_channel.valid?
        # do nothing
      else
        put_model_errors_to_flash(@property_channel.errors, 'redirect')
        redirect_to new_wizard_rate_multiplier_property_channels_path
      end
    end
  end

  # last step, handler to posted channel data
  def create
    init_variables_from_sessions

    if params[:back_button]
      redirect_to new_wizard_rate_multiplier_property_channels_path
    else
      if @property_channel.valid?
        @property_channel.approved = false
        @property_channel.disabled = true
        @property_channel.save

        # save currency conversion if given
        @currency_conversion.save if @currency_conversion.valid?

        flash[:notice] = t('property_channels.create.message.success')
        redirect_to done_creating_property_channels_path
      else
        put_model_errors_to_flash(@property_channel.errors, 'redirect')
        redirect_to new_wizard_confirm_property_channels_path
      end
    end
  end

  # edit channel form
  def edit
    @property_channel = current_property.channels.find(params[:id])
    @currency_conversion = @property_channel.currency_conversion.blank? ? CurrencyConversion.new : @property_channel.currency_conversion
  end

  # handle updated channel
  def update
    @property_channel = current_property.channels.find(params[:id])
    @currency_conversion = @property_channel.currency_conversion.blank? ? CurrencyConversion.new : @property_channel.currency_conversion
    @currency_conversion.property_channel = @property_channel
    
    # save previous disabled value for comparison
    old_disabled = @property_channel.disabled?

    @property_channel.attributes = params[:property_channel]
    @currency_conversion.attributes = params[:currency_conversion] if !@currency_conversion.blank?
   
    if @property_channel.valid? and (@property_channel.currency_conversion.blank? or @currency_conversion.valid?)
      @property_channel.save
      @currency_conversion.save if !@currency_conversion.blank?

      # if disabled changed to enabled then run sync all data
      if old_disabled != @property_channel.disabled and !@property_channel.disabled
        @property_channel.sync_all_data
      end

      # if becomes disabled, alert the members
      create_disabled_changed_alert if old_disabled != @property_channel.disabled
      
      flash[:notice] = t('property_channels.update.message.success')
      redirect_to property_channels_path(:pool_id => @property_channel.pool.id)
    else
      errors = Array.new
      errors << @property_channel.errors
      errors << @currency_conversion.errors if !@currency_conversion.blank?
      put_model_errors_to_flash(errors, 'redirect')
      render :action => "edit"
    end
  end

  private

  # helper for wizard
  def init_variables_from_sessions
    session[:property_channel_params].deep_merge!(params[:property_channel]) if params[:property_channel]
    session[:currency_conversion_params].deep_merge!(params[:currency_conversion]) if params[:currency_conversion]

    @property_channel = PropertyChannel.new(session[:property_channel_params])
    @property_channel.property = current_property

    @property_channel.pool = current_property.pools.first if current_property.single_pool?

    @currency_conversion = CurrencyConversion.new(session[:currency_conversion_params])
    @currency_conversion.property_channel = @property_channel
    
    @channel = @property_channel.channel
  end

  # create channel disabled alert for all the members
  def create_disabled_changed_alert
    if @property_channel.disabled?
      PropertyChannelDisabledAlert.create_for_property(@property_channel)
    else
      PropertyChannelEnabledAlert.create_for_property(@property_channel)
    end
  end

end
