# admin module to manage channel property
class Admin::PropertyChannelsController < Admin::AdminController

  before_filter :user_authenticate

  # edit channel mapping
  def edit
    @property_channel = PropertyChannel.find(params[:id])
    render :layout => 'admin/layouts/no_left_menu'
  end

  # edit channel mapping with left menu view
  def edit_embed
    @property_channel = PropertyChannel.find(params[:id])
  end

  # update channel mapping
  def update
    @property_channel = PropertyChannel.find(params[:id])
    old_disabled = @property_channel.disabled?

    if @property_channel.update_attributes(params[:property_channel])

      puts "#{old_disabled} #{@property_channel.disabled}"

      # notify member about disabled status changes
      create_disabled_changed_alert if old_disabled != @property_channel.disabled

      flash[:notice] = t('property_channels.update.message.success')
      redirect_to setup_admin_property_channels_path
    else
      put_model_errors_to_flash(@property_channel.errors, 'redirect')
      render :action => "edit"
    end
  end

  # update channel mapping without left menu
  def update_embed
    @property_channel = PropertyChannel.find(params[:id])
    old_disabled = @property_channel.disabled?

    if @property_channel.update_attributes(params[:property_channel])
      puts "#{old_disabled} #{@property_channel.disabled}"
      # notify member about disabled status changes
      create_disabled_changed_alert if old_disabled != @property_channel.disabled and @property_channel.approved?

      flash[:notice] = t('property_channels.update.message.success')
      redirect_to admin_property_channels_path
    else
      put_model_errors_to_flash(@property_channel.errors, 'redirect')
      render :action => "edit"
    end
  end

  # approve channel mapping
  def approve
    @property_channel = PropertyChannel.find(params[:id])
    @property_channel.update_attributes(:approved => true, :disabled => false)
    PropertyChannelApprovedAlert.create_for_property(@property_channel, @property_channel.property)
    flash[:notice] = t('admin.properties.approve.message.success')
    redirect_to admin_setup_path
  end

  # new channel mapping
  def new
    session[:property_channel_params] = {}
    session[:currency_conversion_params] = {}
    redirect_to new_wizard_selection_admin_property_channels_path
  end

  # new channel mapping - step 1
  def new_wizard_selection
    init_variables_from_sessions
  end

  # new channel mapping - step 2
  def new_wizard_setting
    init_variables_from_sessions

    @property_channel.skip_channel_specific = true
    @property_channel.skip_rate_conversion_multiplier = true

    if @property_channel.valid?
      # do nothing
    else
      put_model_errors_to_flash(@property_channel.errors, 'redirect')
      redirect_to new_wizard_selection_admin_property_channels_path
    end
  end

  # new channel mapping - step 3
  def new_wizard_conversion
    init_variables_from_sessions
    @property_channel.skip_rate_conversion_multiplier = true

    if params[:back_button]
      redirect_to new_wizard_selection_admin_property_channels_path
    else
      if @property_channel.valid?
        # do nothing
      else
        put_model_errors_to_flash(@property_channel.errors, 'redirect')
        redirect_to new_wizard_setting_admin_property_channels_path
      end
    end
  end

  # new channel mapping - step 4
  def new_wizard_rate_multiplier
    init_variables_from_sessions

    if params[:back_button]
      redirect_to new_wizard_setting_admin_property_channels_path
    else
      if @currency_conversion.valid? or @currency_conversion.to_currency.blank?
        # do nothing
      else
        put_model_errors_to_flash(@currency_conversion.errors, 'redirect')
        redirect_to new_wizard_conversion_admin_property_channels_path
      end
    end
  end

  # new channel mapping - step 5
  def new_wizard_confirm
    init_variables_from_sessions

    if params[:back_button]
      redirect_to new_wizard_conversion_admin_property_channels_path
    else
      if @property_channel.valid?
        # do nothing
      else
        put_model_errors_to_flash(@property_channel.errors, 'redirect')
        redirect_to new_wizard_rate_multiplier_admin_property_channels_path
      end
    end
  end

  # new channel mapping - last step
  def create
    init_variables_from_sessions

    if params[:back_button]
      redirect_to new_wizard_rate_multiplier_admin_property_channels_path
    else
      if @property_channel.valid?
        @property_channel.approved = false
        @property_channel.disabled = true
        @property_channel.save

        @currency_conversion.save if @currency_conversion.valid?

        flash[:notice] = t('property_channels.create.message.success')
        redirect_to admin_property_channels_path
      else
        put_model_errors_to_flash(@property_channel.errors, 'redirect')
        redirect_to new_wizard_confirm_admin_property_channels_path
      end
    end
  end

  def setup
    render :layout => 'admin/layouts/no_left_menu'
  end

  # delete property channel and all of its room type mapping
  def delete
    @property_channel = PropertyChannel.find(params[:id])
    @property_channel.delete

    flash[:notice] = t('property_channels.delete.message.success')
    redirect_to admin_property_channels_path
  end

  private

  # notify member of disabled/enabled channel mapping
  def create_disabled_changed_alert
    if @property_channel.disabled?
      PropertyChannelDisabledAlert.create_for_property(@property_channel)
    else
      PropertyChannelEnabledAlert.create_for_property(@property_channel)
    end
  end

  # helper for channel mapping wizard
  def init_variables_from_sessions
    session[:property_channel_params].deep_merge!(params[:property_channel]) if params[:property_channel]
    session[:currency_conversion_params].deep_merge!(params[:currency_conversion]) if params[:currency_conversion]

    @property_channel = PropertyChannel.new(session[:property_channel_params])
    @property_channel.property = current_admin_property

    @property_channel.pool = current_admin_property.pools.first if current_admin_property.single_pool?

    @currency_conversion = CurrencyConversion.new(session[:currency_conversion_params])
    @currency_conversion.property_channel = @property_channel

    @channel = @property_channel.channel
  end

end
