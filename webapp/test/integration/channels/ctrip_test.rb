require 'test_helper'
require 'integration/integration_test_helper'
 
class CtripTest < ActionDispatch::IntegrationTest
  fixtures :all
  include IntegrationTestHelper

  test "property channel creation" do
    # Create session variables for our test.
    # Session object resulting from this is referenced here:
    # http://api.rubyonrails.org/classes/ActionDispatch/Integration/Session.html
    open_session do |sess|
      property_channel = property_channels(:big_hotel_1_default_ctrip)
      
      puts "about to login"
      login(sess, :super_admin)
      select_property(sess, :big_hotel_1)

      puts "after login"
      puts sess.request.cookie_jar.signed[ApplicationController::MEMBER_AUTH_COOKIE].inspect
      # member = members(:super_admin)
      # sess.request.cookie_jar.signed[ApplicationController::MEMBER_AUTH_COOKIE] = {:value => [member.id, member.salt]}
      # sess.session[:current_property_id] = properties(:big_hotel_1).id

      sess.post(url_for(:controller => 'property_channels', :action => 'new_wizard_setting'), {:property_channel => {
        :pool_id => pools(:test_big_hotel_1).id,
        :channel_id => channels(:ctrip)}}
      )

      puts sess.response.inspect
      session_property_channel = PropertyChannel.new(sess.session[:property_channel_params])
      assert_equal pools(:test_big_hotel_1).id, session_property_channel.pool_id

      # Take note of the settings keys used here (in this case
      # it is :username and :password). Different channel may have
      # different settings and you will need to add them into your
      # form.
      post(url_for(:controller => 'property_channels', :action => 'new_wizard_conversion'), {
        :property_channel => {
          :settings => {
            :username => property_channel.settings(:username),
            :password => property_channel.settings(:password)
          }
        }
      })

      assert_redirected_to redirect_to new_wizard_setting_property_channels_path
      session_property_channel = PropertyChannel.new(sess.session[:property_channel_params])
      assert_equal property_channel.settings(:username), session_property_channel.setting(:username)
    end    
  end
end