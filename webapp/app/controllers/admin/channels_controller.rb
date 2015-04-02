# admin module to manage property
# NOT USED
class Admin::ChannelsController < Admin::AdminController

  before_filter :user_authenticate_and_account_property_selected

  # new property
  def new
    @property = Property.new

    if params[:account_id]
      account = Account.find_by_id(params[:account_id])
      @property.account_id = account.id unless account.blank?
    end
  end

  # Create property
  def create
    @property = Property.new(params[:property])

    if @property.valid?
      @property.save
      redirect_to done_creating_admin_properties_path(:property_id => @property.id)
    else
      put_model_errors_to_flash(@property.errors)
      render 'new'
    end
  end

  # edit property
  def edit
    @property = Property.find(params[:id])
  end

  # update property
  def update
    @property = Property.find(params[:id])

    if @property.update_attributes(params[:property])
      flash[:notice] = t('properties.update.message.success')
      redirect_to admin_properties_path
    else
      put_model_errors_to_flash(@property.errors)
      render :action => "edit"
    end
  end

  # after creating channel
  def done_creating
    @property = Property.active_only.find(params[:property_id])
  end

  def approve
    @property = Property.find(params[:id])
    @property.update_attribute(:approved, true)
    flash[:notice] = t('admin.properties.approve.message.success')
    redirect_to admin_properties_path
  end

end
