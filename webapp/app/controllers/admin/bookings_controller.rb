# admin module to view all bookings
class Admin::BookingsController < Admin::AdminController

  layout 'admin/layouts/no_left_menu'
  
  before_filter :user_authenticate

  # list bookings
  def index
    @bookings = BookingcomBooking.all
  end

  # view booking
  def show
    @booking = BookingcomBooking.find(params[:id])
  end

end
