# admin module to view member alerts
class Admin::BroadcastAlertController < Admin::AdminController

  layout 'admin/layouts/no_left_menu'

  before_filter :user_authenticate

  def create
    if params[:message].blank?
      flash[:alert] = 'Please give a message to broadcast'
      render 'new'
    elsif params[:message].length > 250 or params[:message].length < 5
      flash[:alert] = 'Message must be between 5 to 250 characters'
      render 'new'
    elsif params[:property_ids].blank?
      flash[:alert] = 'Please select a property'
      render 'new'
    else
      params[:property_ids].each do |property_id|
        property = Property.find(property_id)
        BackOfficeAnnouncementAlert.create_for_property(params[:message], property)
      end

      flash[:notice] = 'Alert has been broadcasted'
      redirect_to admin_new_broadcast_alert_path
    end

  end

end
