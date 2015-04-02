# admin module to view member alerts
class Admin::AlertsController < Admin::AdminController

  before_filter :user_authenticate_and_account_property_selected

  def index
    @alerts = current_admin_property.account.members.first.alerts.paginate(:per_page => Alert::DEFAULT_PER_PAGE, :page => params[:page])
  end
  
end
