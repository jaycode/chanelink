# controller for all property related
class PropertiesController < ApplicationController
  load_and_authorize_resource

  layout 'no_left_menu', :except => [:edit_embed, :show_embed]
  
  before_filter :member_authenticate

  # render new form
  def new
    @property = Property.new
    @property.account = current_member.account
  end

  # Create property
  def create
    @property = Property.new(params[:property])
    @property.account = current_member.account

    if @property.valid?
      @property.save
      redirect_to select_properties_path
    else
      put_model_errors_to_flash(@property.errors)
      render 'new'
    end
  end

  # viewing a property
  def show
    @property = current_member.account.properties.find(params[:id])
  end

  # view a property embedded with left menu layout
  def show_embed
    @property = current_member.account.properties.find(params[:id])
    render :layout => 'application'
  end

  # edit form
  def edit
    @property = current_member.account.properties.find(params[:id])
  end

  # edit a property embedded with left menu layout
  def edit_embed
    @property = current_member.account.properties.find(params[:id])
    render :layout => 'application'
  end

  # handle property update
  def update
    @property = current_member.account.properties.find(params[:id])
    
    if @property.update_attributes(params[:property])
      flash[:notice] = t('properties.update.message.success')

      if @property.approved?
        redirect_to edit_embed_property_path(@property)
      else
        redirect_to(@property)
      end
    else
      put_model_errors_to_flash(@property.errors)
      render :action => "edit_embed", :layout => 'application'
    end
  end

  # unused for now
  def do_select
    property = Property.active_only.find_by_id(params[:property_id])

    if property and can_current_member_access_property?(property.id)
      set_current_property(property.id)
      redirect_to dashboard_path
    else
      redirect_to select_properties_path
    end
  end

end
