# controller for room type module
class RoomTypesController < ApplicationController

  load_and_authorize_resource

  before_filter :member_authenticate_and_property_selected

  # new room type form
  def new
    @room_type = RoomType.new
  end

  # room type list
  def index
    @room_types = current_property.room_types
  end

  # room type edit form
  def edit
    @room_type = current_property.room_types.find(params[:id])
  end

  # view room type
  def show
    @room_type = current_property.room_types.find(params[:id])
  end

  # create new room type
  def create
    @room_type = current_property.room_types.new(params[:room_type])
    if @room_type.valid?
      @room_type.save
      redirect_to room_types_path
    else
      put_model_errors_to_flash(@room_type.errors)
      render 'new'
    end
  end

  # update room type
  def update
    @room_type = current_property.room_types.find(params[:id])

    if @room_type.update_attributes(params[:room_type])
      flash[:notice] = t('room_types.update.message.success')
      redirect_to room_types_path
    else
      put_model_errors_to_flash(@room_type.errors)
      render :action => "edit"
    end
  end

  # delete room type
  def delete
    @room_type = current_property.room_types.find(params[:id])
    @room_type.update_attribute(:deleted, true)
    @room_type.clean_up
    redirect_to room_types_path
  end

end
