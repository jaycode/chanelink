class ApplicationController < ActionController::Base
  include ::SslRequirement
  ssl_allowed :all
  protect_from_forgery

  USER_AUTH_COOKIE = 'user_chanelink_auth'
  MEMBER_AUTH_COOKIE = 'member_chanelink_auth'
  LOCALE_COOKIE = 'chanelink_locale'

  before_filter :set_locale, :set_cache_buster

  # expire cache when user press back on browser
  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  # catch for access denied
  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = I18n.t('general.access_denied')
    redirect_to dashboard_path
  end

  # catch for all errors
  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception, :with => :render_error
    rescue_from ActionController::InvalidAuthenticityToken, :with => :render_session_expired
    rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
    rescue_from ActionController::UnknownController, :with => :render_not_found
    rescue_from ActionController::UnknownAction, :with => :render_not_found
  end
  
  # Returns the currently logged in member or nil if there isn't one
  def current_member
    return unless cookies.signed[MEMBER_AUTH_COOKIE]
    @current_member ||= Member.authenticate_with_salt(*cookies.signed[MEMBER_AUTH_COOKIE])
  end

  # Returns the currently selected property
  def current_property
    return if session[:current_property_id].blank?
    @current_property ||= Property.active_only.find(session[:current_property_id])
  end

  # return access object for current user
  def current_ability
    @current_ability ||= Ability.new(current_member, current_property)
  end

  # set current property
  def set_current_property(property_id)
    session[:current_property_id] = property_id
  end
  
  # Make current_member available in templates as a helper
  helper_method :current_member

  # Make current_member available in templates as a helper
  helper_method :current_property

  # Filter method to enforce a login requirement & email validation
  # Apply as a before_filter on any controller you want to protect
  def member_authenticate_and_property_selected
    if member_logged_in?
      if current_member.prompt_password_change? and !session[:master_password_used]
        redirect_to prompt_password_member_path(current_member)
      else
        property_selected
      end
    else
      member_access_denied
    end
  end

  # Filter method to enforce a login requirement & email validation
  # Apply as a before_filter on any controller you want to protect
  def member_authenticate
    if member_logged_in?
      if current_member.prompt_password_change? and !session[:master_password_used]
        redirect_to prompt_password_member_path(current_member)
      end
    else
      member_access_denied
    end
  end

  # get cur
  def property_selected
    if current_property.blank?
      # if has only one property, then just use that oen
      if current_member.properties.count == 1
        set_current_property(current_member.properties.first.id)
        redirect_to dashboard_path
      # member has access to more than one property? bring up property selection
      elsif current_member.properties.count > 1
        redirect_to select_properties_path
      # no property
      elsif current_member.properties.count == 0
        redirect_to no_registered_property_properties_path
      end
    end
  end

  # function to check is a member currently logged in
  def member_logged_in?
    current_member.is_a? Member
  end

  # Make logged_in? available in templates as a helper
  helper_method :member_logged_in?

  # handle access denied
  def member_access_denied
    flash[:longer_notice] = t('general.access_denied')
    redirect_target = login_path
    redirect_target = params[:denied_redirect] if params[:denied_redirect]
    redirect_away redirect_target
  end

  # redirect somewhere that will eventually return back to here
  def redirect_away(*params)
    session[:original_uri] = request.fullpath
    redirect_to(*params)
  end

  # returns the person to either the original url from a redirect_away or to a default url
  def redirect_back(*params)
    uri = session[:original_uri]
    session[:original_uri] = nil
    if uri
      redirect_to uri
    else
      redirect_to(*params)
    end
  end

  # put model error into flash in form of array
  def put_model_errors_to_flash(errors, type = 'render')
    errors_array = Array.new

    # if errors is array of OrderedHash lets iterate through
    if errors.is_a?(Array)
      errors.each do |error|
        error.full_messages.each do |msg|
          errors_array << msg
        end
      end
    else
      errors.full_messages.each do |msg|
        errors_array << msg
      end
    end

    if type == 'render'
      flash.now[:model_alert] = errors_array
    elsif type == 'redirect'
      flash[:model_alert] = errors_array
    end
  end

  # store member id and salt in cookie
  def create_member_auth_cookie(member)
    # create permanent cookie if remember me
    if params[:remember_me]
      session[:remember_me_used] = true
      cookies.permanent.signed[MEMBER_AUTH_COOKIE] = {:value => [member.id, member.salt]}
    else
      # create normal cookie
      cookies.signed[MEMBER_AUTH_COOKIE] = {:value => [member.id, member.salt]}
    end
  end

  # set selected locale
  def set_locale_cookie(value)
    cookies.permanent[LOCALE_COOKIE] = value
  end

  # get selected locale
  def get_locale_cookie
    cookies[LOCALE_COOKIE]
  end

  # not used now but keep it in case if in the future we need it
  def set_locale
    #if params[:locale] is nil then I18n.default_locale will be used
    if params[:locale].nil?
      if get_locale_cookie.nil?
        # set default
        I18n.locale = :en
      else
        I18n.locale = get_locale_cookie
      end
    else
      set_locale_cookie params[:locale]
      I18n.locale = get_locale_cookie
    end
  end

  private

  # function to handle user inactivity
  def check_last_seen
    if member_logged_in? and !session[:remember_me_used]
      # if idle for 5 minutes then kick user out
      if session[:last_seen] < 5.minutes.ago
        reset_session
        cookies.delete MEMBER_AUTH_COOKIE
        flash[:notice] = t('login.message.inactivity')

        redirect_to root_path
      else
        # update last seen
        session[:last_seen] = DateTime.now
      end
    end
  end

  def render_not_found(exception)
    render :template =>"/error/404", :layout => 'no_left_menu', :status => 404
  end

  def render_error(exception)
    render :template =>"/error/500", :layout => 'no_left_menu', :status => 500
  end

  def render_session_expired(exception)
    render :template =>"/error/session_expired", :layout => 'no_left_menu', :status => 500
  end

  def render_mobile_template_not_found
    @hide_notification = true
    render :template =>"/error/template_not_found"
  end

  # method to make sure current member has the access to a property
  def can_current_member_access_property?(property_id)
    if current_member and !Property.active_only.find_by_id_and_account_id(property_id, current_member.account.id).blank?
      if (current_member.super_member?) or
          !MemberPropertyAccess.find_by_member_id_and_property_id(current_member.id, property_id).blank?
        true
      else
        false
      end
    else
      false
    end
  end

  helper_method :date_to_key

  def date_to_key(date)
    date.strftime('%F')
  end

  def to_boolean(s)
    !s.to_i.zero?
  end

end
