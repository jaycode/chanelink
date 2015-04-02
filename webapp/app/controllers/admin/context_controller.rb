# context selection for navigating through admin interface
class Admin::ContextController < Admin::AdminController

  layout 'admin/layouts/no_left_menu'

  before_filter :user_authenticate

  # render select property UI
  def select_property
    @account = nil
    if params[:account_id]
      @account = Account.find(params[:account_id])
    else
      if current_user.super?
        @account = Account.first
      else
        @account = current_user.assigned_accounts.first
      end
    end
  end

  # do select context property
  def select_property_set
    prop = Property.find(params[:id])
    set_current_admin_property(prop.id)
    redirect_to admin_dashboard_path
  end

  # do switch context property
  def switch_property
    clean_current_admin_property
    redirect_to admin_select_property_path
  end

end
