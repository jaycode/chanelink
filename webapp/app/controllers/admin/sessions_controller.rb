# Session controller to manage login and logout
# for User
class Admin::SessionsController < Admin::AdminController

  skip_before_filter :user_authenticate

  layout 'admin/layouts/login'
  
  # For Login Submission
  def create
    user = User.authenticate(params[:email], params[:password])
    user_no_password_check = User.find_by_email(params[:email])

    # If already logged in then return to root path
    if user_logged_in?
      redirect_to admin_root_path

    # Try to authenticate given email and password
    elsif user
      create_user_auth_cookie(user)
      user.logins.create(:success => true)
      session[:last_seen] = DateTime.now
      flash[:notice] = t('login.message.success')
      redirect_back admin_login_path
    else

      if user_no_password_check
        # lock user if failed login for 3 times
        user_no_password_check.logins.create(:success => false)
        if user_no_password_check.logins.failed_in_the_last_hour_after_last_update(user_no_password_check.updated_at).count >= User::TIMES_FAILED_BEFORE_LOCKING
          user_no_password_check.lock
          flash.now[:alert] = t('login.message.locked', :times => User::TIMES_FAILED_BEFORE_LOCKING)
        else
          flash.now[:alert] = t('login.message.fail')
        end
      else
        flash.now[:alert] = t('login.message.fail')
      end

      render :action => 'new'
    end
  end

  # For Login Form
  def new
    if user_logged_in?
      redirect_to admin_dashboard_path
    end
  end

  # For Logout
  def destroy
    if user_logged_in?
      reset_session
      cookies.delete USER_AUTH_COOKIE
      flash[:notice] = t('admin.logout.message.success')
    end
    redirect_to admin_root_path
  end

end
