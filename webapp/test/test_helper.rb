ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  
  # Logs in the user
  def login(account)
    member = members(account)
    @request.cookie_jar.signed[ApplicationController::MEMBER_AUTH_COOKIE] = {:value => [member.id, member.salt]}
  end

  def select_property(property)
    session[:current_property_id] = properties(property).id
  end
end
