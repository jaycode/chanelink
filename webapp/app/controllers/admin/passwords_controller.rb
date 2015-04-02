class Admin::PasswordsController < Admin::AdminController

  layout 'layouts/login'

  # reset password for backoffice user
  def reset_submit
    email = params[:email]

    if email.blank?
      flash.now[:alert] = t('password.reset.message.email_not_given')
      render :action => 'reset'
    elsif User.find_by_email(email).blank?
      flash.now[:alert] = t('password.reset.message.member_not_found')
      render :action => 'reset'
    else
      user = User.find_by_email(email)
      user.reset_password
      flash[:notice] = t('password.reset.message.check_email')
      redirect_to admin_login_path
    end
  end
  
end
