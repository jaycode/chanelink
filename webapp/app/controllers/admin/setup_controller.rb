# not used
class Admin::SetupController < Admin::AdminController

  layout 'admin/layouts/no_left_menu'

  before_filter :user_authenticate

end
