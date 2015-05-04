	require 'rails_helper'

	describe 'Ctrip Update Availabilities', :type => :feature do
		include IntegrationTestHelper
		include Capybara::DSL

		# Somehow before :all is loaded before fixtures loaded so we cannot use that.
		before(:each) do
			user = users(:super_admin)
			login_backend user.email, 'testpass'
			select_property_backend properties(:big_hotel_1).id
		end

		describe 'getting room prices' do
			channel 	= CtripChannel.first
			room_types 	= nil

			scenario 'request data' do
				begin
					room_types = channel.room_type_fetcher.retrieve(properties(:big_hotel_1), false, '2015-05-01', '2015-05-02')
				rescue Exception => e
					puts 'Error: #{e.message}'
				end
        expect(room_types.count).to be > 0
			end
		end

    describe 'updating availabilities' do
      it 'should update the prices in their server' do
        # In here, use test that requires Capybara. If we are only testing classes, use models/channels/xxx.rb
      end
    end
	end