# Session controller to manage login and logout
class SessionsController < ApplicationController
  ssl_required :new, :create
  layout 'layouts/login'
  
  # For Login Submission
  def create
    member = Member.authenticate(params[:email], params[:password], session)
    member_no_password_check = Member.find_by_email(params[:email])
    
    # If already logged in then return to root path
    if member_logged_in?
      redirect_to root_path
      
    # Try to authenticate given email and password
    elsif member
      if member.disabled?
        flash[:alert] = t('login.message.disabled')
        redirect_to login_path
      else
        create_member_auth_cookie(member)
        member.logins.create(:success => true)
        session[:last_seen] = DateTime.now
        flash[:notice] = t('login.message.success')
        redirect_back root_path
      end
    else
      if member_no_password_check
        member_no_password_check.logins.create(:success => false)
        # if member does wrong login 3 times then lock the user
        if member_no_password_check.logins.failed_in_the_last_hour_after_last_update(member_no_password_check.updated_at).count >= Member::TIMES_FAILED_BEFORE_LOCKING
          member_no_password_check.lock 
          flash.now[:alert] = t('login.message.locked', :times => Member::TIMES_FAILED_BEFORE_LOCKING)
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
    if member_logged_in?
      redirect_to dashboard_path
    end
  end

  # For Logout
  def destroy
    if member_logged_in?
      reset_session
      cookies.delete MEMBER_AUTH_COOKIE
      flash[:notice] = t('logout.message.success')
    end
    redirect_to root_path
  end

  def inactive
    if member_logged_in? and !session[:remember_me_used]
      reset_session
      cookies.delete MEMBER_AUTH_COOKIE
      flash[:notice] = t('login.message.inactivity')
    end
    redirect_to root_path
  end

end
