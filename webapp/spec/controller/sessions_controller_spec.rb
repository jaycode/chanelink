require 'rails_helper'

describe 'SessionsController', :type => :controller do
	scenario 'should get new page' do
		#get :new
		# # This returns 302 instead of success, because we got ssl_required :new, :create
		# # assert_response :success
		# # To find out all elements of Rails url, check here:
		# # http://apidock.com/rails/ActionController/Base/url_for
		# assert_redirected_to :protocol => 'https'

		# # This is required as :new action uses ssl_required (see it in the controller).
		# @request.env['HTTPS'] = 'on'
		# get :new
		# # You can use @response.inspect to see if the page is being redirected and other header information.
		# # puts @response.inspect
		# assert_response :success
	end

	scenario 'member login' do
		# # In this method we will try to login with a member account
		# # as stored in fixture members.yml.

		# @request.env['HTTPS'] = 'on'

		# email = 'jay@chanelink.com'
		# pass = 'testpass'

		# post(:create, {:email => email, :password => pass})
		# assert_kind_of String, ApplicationController::MEMBER_AUTH_COOKIE

		# # Simply using cookies.signed[ApplicationController::MEMBER_AUTH_COOKIE] does not work
		# # because in Rails test cookies are simple hash.
		# puts 'cookies value: #{@request.cookie_jar.signed[ApplicationController::MEMBER_AUTH_COOKIE].inspect}'
		# member = Member.authenticate_with_salt(*@request.cookie_jar.signed[ApplicationController::MEMBER_AUTH_COOKIE])

		# puts member.inspect
		# assert_equal(member.email, email)
	end

	# Next please continue to test/functional/property_channels_controller_test.rb
	# for an example of real-world case where you log in and do changes on the app.
end