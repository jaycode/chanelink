# admin mdoule to handle room type
class Admin::RoomTypesController < Admin::AdminController
  
  before_filter :user_authenticate_and_account_property_selected

  # new room type
  def new
    @room_type = current_admin_property.room_types.new
  end

  # list room type
  def index
    @room_types = current_admin_property.room_types
  end

  # edit room type
  def edit
    @room_type = current_admin_property.room_types.find(params[:id])
  end

  # view room type
  def show
    @room_type = current_admin_property.room_types.find(params[:id])
  end

  # create room type
  def create
    @room_type = current_admin_property.room_types.new(params[:room_type])
    if @room_type.valid?
      @room_type.save
      redirect_to admin_room_types_path
    else
      put_model_errors_to_flash(@room_type.errors)
      render 'new'
    end
  end

  # update room type
  def update
    @room_type = current_admin_property.room_types.find(params[:id])

    if @room_type.update_attributes(params[:room_type])
      flash[:notice] = t('room_types.update.message.success')
      redirect_to admin_room_types_path
    else
      put_model_errors_to_flash(@room_type.errors)
      render :action => "edit"
    end
  end

  # delete room type
  def delete
    @room_type = current_admin_property.room_types.find(params[:id])
    @room_type.update_attribute(:deleted, true)
    @room_type.clean_up
    redirect_to admin_room_types_path
  end

end
