# controller to handle dashboard view
class DashboardController < ApplicationController

  before_filter :member_authenticate_and_property_selected

end
