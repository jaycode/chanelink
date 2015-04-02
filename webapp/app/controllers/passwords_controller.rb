# handle reset password for member
class PasswordsController < ApplicationController

  layout 'layouts/login'

  def reset_submit
    email = params[:email]

    # if email field is not given
    if email.blank?
      flash.now[:alert] = t('password.reset.message.email_not_given')
      render :action => 'reset'
    # email given, but no member exist with that email
    elsif Member.find_by_email(email).blank?
      flash.now[:alert] = t('password.reset.message.member_not_found')
      render :action => 'reset'
    else
      # found the member, do reset password
      member = Member.find_by_email(email)
      member.reset_password
      flash[:notice] = t('password.reset.message.check_email')
      redirect_to login_path
    end
  end
  
end
