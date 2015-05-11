# admin module to manage properties
class Admin::PropertiesController < Admin::AdminController

  # before_filter :user_authenticate_and_account_property_selected
  before_filter :user_authenticate

  # new property
  def new
    @property = Property.new

    if params[:account_id]
      account = Account.find_by_id(params[:account_id])
      @property.account_id = account.id unless account.blank?
    end

    render :layout => 'admin/layouts/no_left_menu'
  end

  # Create property
  def create
    @property = Property.new(params[:property])

    if @property.valid?
      @property.save
      UserPropertyAccess.create(:user_id => current_user.id, :property_id => @property.id) unless current_user.super?
      
      set_current_admin_property(@property.id)
      redirect_to admin_dashboard_path
    else
      put_model_errors_to_flash(@property.errors)
      render 'new', :layout => 'admin/layouts/no_left_menu'
    end
  end

  # edit property
  def edit
    @property = Property.find(params[:id])
  end

  # list property
  def manage
    @property = Property.find(params[:id])
    render :layout => 'admin/layouts/no_left_menu'
  end

  # update property
  def update
    @property = Property.find(params[:id])
    if @property.update_attributes(params[:property])
      flash[:notice] = t('properties.update.message.success')
      redirect_to admin_dashboard_path
    else
      put_model_errors_to_flash(@property.errors)
      render :action => "edit"
    end
  end

  # after creating property
  def done_creating
    @property = Property.active_only.find(params[:property_id])
  end

  # approve property
  def approve
    # requirements to approve property
    if @property.channels.count == 0
      flash[:alert] = t("admin.accounts.activate.message.no_channels")
    elsif @property.room_types.count == 0
      flash[:alert] = t("admin.accounts.activate.message.no_room_type")
    elsif RoomTypeChannelMapping.room_type_ids(@property.room_type_ids).count != (@property.room_types.count * @property.channels.count)
      flash[:alert] = t("admin.accounts.activate.message.no_room_type_channel_mapping")
    else
      @property = Property.find(params[:id])
      @property.update_attribute(:approved, true)
      flash[:notice] = t('admin.properties.approve.message.success')
      redirect_to admin_properties_path
    end
  end

  # handle both approve and reject property
  def approve_reject
    @property = Property.find(params[:id])
    @property.attributes = params[:property]
    if @property.valid?
      if params[:approve]
        # check requirement for property approval
        if @property.currency.blank?
          flash[:alert] = t("admin.properties.approve.message.no_currency")
        elsif @property.channels.count == 0
          flash[:alert] = t("admin.properties.approve.message.no_channels")
        elsif @property.room_types.count == 0
          flash[:alert] = t("admin.properties.approve.message.no_room_type")
        elsif RoomTypeChannelMapping.room_type_ids(@property.room_type_ids).count != (@property.room_types.count * @property.channels.count)
          flash[:alert] = t("admin.properties.approve.message.no_room_type_channel_mapping")
        else
          @property.approved = true
          @property.rejected = false
          flash[:notice] = t('properties.update.message.approved')
        end
     # reject a property
      else params[:reject]
        @property.approved = false
        @property.rejected = true
        flash[:notice] = t('properties.update.message.rejected')
      end
      @property.save
      
      redirect_to admin_setup_path
    else
      put_model_errors_to_flash(@property.errors)
      render :action => "manage", :layout => 'admin/layouts/no_left_menu'
    end
  end

  # delete property
  def delete
    @property = Property.find(params[:id])
    @property.update_attribute(:deleted, true)
    clean_current_admin_property
    flash[:notice] = t("admin.properties.delete.message.success")
    redirect_to admin_setup_path
  end

  def index
    render :layout => 'admin/layouts/no_left_menu'
  end

  # view a property
  def show
    @property = Property.find(params[:id])
    render :layout => 'admin/layouts/no_left_menu'
  end

end
