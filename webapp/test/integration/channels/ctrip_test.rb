# This class is only used for a reference on how to do testing with access to session.

require 'test_helper'
require 'integration/integration_test_helper'
require 'capybara/rails'

class CtripTest < ActionDispatch::IntegrationTest
  fixtures :all
  include IntegrationTestHelper::Rails
  include Capybara::DSL
  
  test "property channel creation" do
    # Create session variables for our test.
    # Session object resulting from this is referenced here:
    # http://api.rubyonrails.org/classes/ActionDispatch/Integration/Session.html
    # sess = Capybara::Session.new(:rack_test, Capybara.app)

    open_session do |sess|
      property_channel = property_channels(:big_hotel_1_default_ctrip)
      
      login(sess, :super_admin)
      select_property(sess, :big_hotel_1)

      puts "after login, session is:"
      puts sess.request.cookie_jar.signed[ApplicationController::MEMBER_AUTH_COOKIE].inspect

      sess.post '/property_channels/new_wizard_setting',
        :property_channel => {
          :pool_id => pools(:test_big_hotel_1).id,
          :channel_id => channels(:ctrip)
        }
      
      session_property_channel = PropertyChannel.new(sess.session[:property_channel_params])
      assert_equal pools(:test_big_hotel_1).id, session_property_channel.pool_id

      # Take note of the settings keys used here (in this case
      # it is :username and :password). Different channel may have
      # different settings and you will need to add them into your
      # form.
      sess.post(url_for(:controller => 'property_channels', :action => 'new_wizard_conversion'), {
        :property_channel => {
          :settings => {
            :username => property_channel.settings(:username),
            :password => property_channel.settings(:password)
          }
        }
      })
      # sess.visit '/property_channels/new_wizard_setting'
      # sess.save_and_open_page
      # sess.fill_in 'property_channel_settings_username', :with => property_channel.settings(:username)
      # sess.fill_in 'property_channel_settings_password', :with => property_channel.settings(:password)
      # sess.click_button 'continue'


      assert_equal url_for(:controller => 'property_channels', :action => 'new_wizard_setting'), sess.response.location
      session_property_channel = PropertyChannel.new(sess.session[:property_channel_params])
      assert_equal property_channel.settings(:username), session_property_channel.settings(:username)

      visit '/property_channels/new_wizard_conversion'
    end
  end
end