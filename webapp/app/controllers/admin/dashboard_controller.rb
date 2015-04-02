require "rexml/document"

# admin dashboard module
class Admin::DashboardController < Admin::AdminController

  before_filter :user_authenticate_and_account_property_selected, :except => [:xml_body, :xml_log, :rerun_change_set, :bookingcom_update, :bookingcom_update_set]

  # view xml body
  def xml_body
    @cs = ChangeSetChannelLog.find(params[:id])
    render :layout => 'admin/layouts/no_left_menu'
  end

  # view xml push list
  def xml_log
    @log = ChangeSetChannelLog.order("created_at desc").paginate(:per_page => 25, :page => params[:page])
    render :layout => 'admin/layouts/no_left_menu'
  end

  # handle rerun xml push
  def rerun_change_set
    cs = ChangeSetChannelLog.find(params[:id])
    cs.change_set_channel.delay.run
    flash[:notice] = 'Rerun job created'
    redirect_to admin_xml_log_path
  end

  # booking.com module for certification purpose
  def bookingcom_update
    render :layout => 'admin/layouts/no_left_menu'
  end

  # booking.com module for certification purpose
  def bookingcom_update_set
    @property_id = params[:property_id]
    @room_type_id = params[:room_type_id]
    @rate_plan_id = params[:rate_plan_id]
    @date_from = params[:date_from]
    @date_to = params[:date_to]
    @rate = params[:rate]
    @single_rate = params[:single_rate]
    @min_stay = params[:min_stay]
    @cta = params[:cta]
    @ctd = params[:ctd]
    @stop_sell = params[:stop_sell]

    if @property_id.blank? or @room_type_id.blank? or @rate_plan_id.blank? or @date_from.blank? or @date_to.blank?
      flash[:notice] = 'Please give all parameter'
      redirect_to admin_bookingcom_update_path
    elsif @rate.blank? and @single_rate.blank? and @min_stay.blank? and @cta.blank? and @ctd.blank? and @stop_sell.blank?
      flash[:notice] = 'Please give a value to push'
      redirect_to admin_bookingcom_update_path
    else
      date_from = Date.strptime(@date_from)
      date_to = Date.strptime(@date_to)

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.request {
          xml.username BookingcomChannel::USERNAME
          xml.password BookingcomChannel::PASSWORD
          xml.hotel_id @property_id
          xml.room(:id => @room_type_id) {
            while date_from <= date_to
              xml.date(:value => date_from.strftime('%F')) {
                xml.rate(:id => @rate_plan_id)
                xml.price @rate unless @rate.blank?
                xml.price1 @single_rate unless @single_rate.blank?
                xml.minimumstay @min_stay unless @min_stay.blank?
                xml.closedonarrival @cta unless @cta.blank?
                xml.closedondeparture @ctd unless @ctd.blank?
                xml.closed @stop_sell unless @stop_sell.blank?
              }
              date_from = date_from + 1.day
            end
          }
        }
      end

      request_xml = builder.to_xml

      res = BookingcomChannel.post_xml(request_xml, BookingcomChannel::AVAILABILITY)
      ChangeSetChannelLog.create(:request_xml => request_xml, :response_xml => res)
      flash[:notice] = 'Done sending XML'
      redirect_to admin_bookingcom_update_path
    end
  end

end
