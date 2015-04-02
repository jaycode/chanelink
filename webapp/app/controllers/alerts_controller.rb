# controller class for alert related
class AlertsController < ApplicationController

  # list alert for a member
  def index
    @alerts = Alert.by_member_and_property(current_member.id, current_property.id).paginate(:per_page => Alert::DEFAULT_PER_PAGE, :page => params[:page])
    @alerts.each do |d|
      d.previous_read = d.read
      d.update_attribute(:read, true)
    end
  end

  # delete alert
  def delete
    if params[:alert_ids]
      # go through each selected alert and delete them
      params[:alert_ids].each do |alert_id|
        alert = current_member.alerts.find(alert_id)
        alert.update_attribute(:deleted, true)
      end
    end
    redirect_to alerts_path
  end
  
end
