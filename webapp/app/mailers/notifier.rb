# send email for general use
class Notifier < ActionMailer::Base
  
  default :from => "#{APP_CONFIG[:noreply_email]}"

  def email_member_password(password, member)
    @password = password
    @member = member
    @receiver = @member.name

    mail :to => @member.email, :subject => t('notifier.email_member_password.subject')
  end

  def email_user_password(password, user)
    @password = password
    @user = user
    @receiver = @user.name

    mail :to => @user.email, :subject => t('notifier.email_user_password.subject')
  end

  def email_member_reset_password(password, member)
    @password = password
    @member = member
    @receiver = @member.name

    mail :to => @member.email, :subject => t('notifier.email_member_reset_password.subject')
  end

  def email_user_reset_password(password, user)
    @password = password
    @user = user
    @receiver = @user.name

    mail :to => @user.email, :subject => t('notifier.email_member_reset_password.subject')
  end

  def email_member_lock_password(password, member)
    @password = password
    @member = member
    @receiver = @member.name

    mail :to => @member.email, :subject => t('notifier.email_member_lock_password.subject')
  end

  def email_user_lock_password(password, user)
    @password = password
    @user = user
    @receiver = @user.name

    mail :to => @user.email, :subject => t('notifier.email_member_lock_password.subject')
  end

  def email_expedia_booking_notification(email, booking)
    @booking = booking
    mail :to => email, :subject => t("notifier.email_expedia_booking_#{booking.booking_status.name}.subject")
  end

  def email_bookingcom_booking_notification(email, booking)
    @booking = booking
    mail :to => email, :subject => t("notifier.email_expedia_booking_#{booking.booking_status.name}.subject")
  end
  
end
