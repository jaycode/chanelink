# controller for rate type module
class RateTypesController < ApplicationController

  load_and_authorize_resource

  before_filter :member_authenticate_and_property_selected

  def new
    @rate_type = RateType.new
  end

  def index
    @rate_type = RateType.where(['deleted != 1 AND id = ? AND (account_id = ? OR account_id IS NULL)', params[:id], current_property.account_id]).all
  end

  def edit
    @rate_type = RateType.where(['deleted != 1 AND id = ? AND (account_id = ? OR account_id IS NULL)', params[:id], current_property.account_id]).first
  end

  def show
    @rate_type = RateType.where(['deleted != 1 AND id = ? AND (account_id = ? OR account_id IS NULL)', params[:id], current_property.account_id]).first
  end

  def create
    params[:rate_type][:account_id] = current_property.account_id
    @rate_type = RateType.new(params[:rate_type])
    if @rate_type.valid?
      @rate_type.save
      redirect_to rate_types_path
    else
      put_model_errors_to_flash(@rate_type.errors)
      render 'new'
    end
  end

  def update
    @rate_type = RateType.find(params[:id])

    if @rate_type.account_id != current_property.account_id
      flash[:notice] = t('rate_types.update.message.diff_account')
      redirect_to rate_types_path
    else
      if @rate_type.update_attributes(params[:rate_type])
        flash[:notice] = t('rate_types.update.message.success')
        redirect_to rate_types_path
      else
        put_model_errors_to_flash(@rate_type.errors)
        render :action => "edit"
      end
    end
  end

  def delete
    @rate_type = RateType.find(params[:id])
    if @rate_type.account_id != current_property.account_id
      flash[:notice] = t('rate_types.update.message.diff_account')
      redirect_to rate_types_path
    else
      @rate_type.update_attribute(:deleted, true)
      @rate_type.clean_up
      redirect_to rate_types_path
    end
  end

end
