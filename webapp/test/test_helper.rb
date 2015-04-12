ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Rails cannot load different fixtures per each test case so we have to load all of them here.
  fixtures :all
  # Helper Methods
  #-----------------------

  # Helper methods below will only work for functional tests. For integration test use
  # test/integration/integration_test_helper.rb

  # Logs in the user
  def login(account)
    member = members(account)
    @request.cookie_jar.signed[ApplicationController::MEMBER_AUTH_COOKIE] = {:value => [member.id, member.salt]}
  end

  def select_property(property)
    session[:current_property_id] = properties(property).id
  end
end
