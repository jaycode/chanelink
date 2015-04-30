require 'rails_helper'

describe 'UpdateAvaibilities', :type => :feature do
	include IntegrationTestHelper
	include Capybara::DSL

	# Somehow before :all is loaded before fixtures loaded so we cannot use that.
	before(:each) do
		user = users(:super_admin)
		login_backend user.email, 'testpass'
		select_property_backend properties(:big_hotel_1).id
	end

	describe 'get ctrip channel room prices for testing' do
		channel 	= CtripChannel.first
		room_types 	= nil

		scenario 'request data' do
			begin
		      room_types = channel.room_type_fetcher.retrieve(properties(:big_hotel_1), false, '2015-05-01', '2015-05-02')
		    rescue Exception => e
		      puts 'Error: #{e.message}'
		    end
		end

		it 'should room_types.count > 0' do
			expect(room_types.count).to be > 0
		end
  	end
end