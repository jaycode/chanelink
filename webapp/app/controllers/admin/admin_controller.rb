class Admin::AdminController < ApplicationController

  layout 'admin/layouts/admin'
  
  # Returns the currently logged in user or nil if there isn't one
  def current_user
    return unless cookies.signed[USER_AUTH_COOKIE]
    @current_user ||= User.authenticate_with_salt(*cookies.signed[USER_AUTH_COOKIE])
  end

  # Returns the currently selected property
  def current_admin_property
    return if session[:current_admin_property_id].blank?
    @current_admin_property ||= Property.find(session[:current_admin_property_id])
  end

  # Returns the currently selected account
  def current_admin_account
    return if session[:current_admin_account_id].blank?
    @current_admin_account ||= Account.find(session[:current_admin_account_id])
  end
  
  # Make current_user available in templates as a helper
  helper_method :current_user
  helper_method :current_admin_property
  helper_method :current_admin_account

  # Filter method to enforce a login requirement
  # Apply as a before_filter on any controller you want to protect
  def user_authenticate
    if user_logged_in?
      # do nothing
    else
      user_access_denied
    end
  end
  
  def user_logged_in?
    current_user.is_a? User
  end

  # Make logged_in? available in templates as a helper
  helper_method :user_logged_in?

  # set current property
  def set_current_admin_property(property_id)
    session[:current_admin_property_id] = property_id
  end

  # set current property
  def clean_current_admin_property
    session[:current_admin_property_id] = nil
  end

  # handle access denied
  def user_access_denied
    flash[:longer_notice] = t('general.access_denied')
    redirect_target = admin_login_path
    redirect_target = params[:denied_redirect] if params[:denied_redirect]
    redirect_away redirect_target
  end

  # store user id and salt in cookie
  def create_user_auth_cookie(user)
    # create permanent cookie if remember me
    if params[:remember_me]
      cookies.permanent.signed[USER_AUTH_COOKIE] = {:value => [user.id, user.salt]}
    else
      # create normal cookie
      cookies.signed[USER_AUTH_COOKIE] = {:value => [user.id, user.salt]}
    end
  end

  # check if user is logged in and a property is selected
  def user_authenticate_and_account_property_selected
    if user_logged_in?
      if current_user.prompt_password_change?
        redirect_to prompt_password_admin_user_path(current_user)
      else
        admin_account_property_selected
      end
    else
      user_access_denied
    end
  end

  def admin_account_property_selected
    if current_admin_property.blank?
      redirect_to admin_select_property_path
    end
  end

  def current_ability
    @current_ability ||= AdminAbility.new(current_user)
  end

  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = I18n.t('general.access_denied')
    redirect_to admin_dashboard_path
  end

end
