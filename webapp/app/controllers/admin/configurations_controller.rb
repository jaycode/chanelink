# account module for back office
class Admin::ConfigurationsController < Admin::AdminController

  layout 'admin/layouts/no_left_menu'

  # new account form
  def edit
    @configuration = Configuration.first
  end

  # update account
  def update
    @configuration = Configuration.first

    if @configuration.update_attributes(params[:configuration])
      flash[:notice] = t('admin.configurations.update.message.success')
      redirect_to admin_dashboard_path
    else
      put_model_errors_to_flash(@configuration.errors)
      render :action => "edit"
    end
  end

end
