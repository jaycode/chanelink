class BulkUpdateController < ApplicationController

  before_filter :member_authenticate_and_property_selected

  # render the user interface for bulk update
  def tool
    @bulk_update = BulkUpdate.new
  end

  # handle when bulk update form is submitted
  def submit
    @bulk_update = BulkUpdate.new(params[:bu])
    @bulk_update.property = current_property
    if @bulk_update.valid?
      @bulk_update.do_update
      flash[:notice] = t('bulk_update.tool.message.success')
      redirect_to bulk_update_path
    else
      put_model_errors_to_flash(@bulk_update.errors)
      render 'tool'
    end
  end
  
end
