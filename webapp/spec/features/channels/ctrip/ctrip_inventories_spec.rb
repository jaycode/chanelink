  require 'rails_helper'

  # In here, use test that requires Capybara. If we are only testing classes, use models/channels/xxx.rb
  describe 'Ctrip Inventories Spec', :type => :feature do
    include IntegrationTestHelper
    include Capybara::DSL

    # Somehow before :all is loaded before fixtures loaded so we cannot use that.
    before(:each) do
      member = members(:super_admin)
      login member.email, 'testpass'
      property = properties(:big_hotel_1)
      select_property property.id

      # ADD YOUR CODE HERE:
      #----------------------------------
      @pool_id = pools(:default_big_hotel_1).id
      @channel_id = channels(:ctrip).id
      @channel_code = 'ctrip'
      #----------------------------------
    end
    describe 'update rates' do
      scenario 'updating with master rates' do
        # For testing if changeset is actually created, we delete
        # all changesets first.
        ChangeSet.delete_all

        visit "/inventories?pool_id=#{@pool_id}"
        # Fill in a master price input with a value then save it.
        today = DateTime.now.beginning_of_day.to_date
        room_type = room_types(:superior)
        
        puts "element to find: #master_rates-form [name=\"[#{room_type.id}][#{today.to_s}][amount]\"]"

        14.times do |i|
            find(:css, "#master_rates-form [name=\"[#{room_type.id}][#{(today + i).to_s}][amount]\"]").set(300000)
        end
        
        click_button "master_rates-save"

        save_and_open_page
        # The next page should have all associated channel room prices changed.
        within "##{@channel_code}_room_type-#{room_type.id}" do
          14.times do |i|
            price_cell = find(:css, ".smallColumn:nth-child(#{i+2})")
            expect(price_cell.native.text.strip.to_f).to eq(300000.0)
          end
        end

        # From here xml is being passed to delayed job. We can see if it is properly entered here, but to
        # find out if xml is properly sent and proper response received, check on models/channels/[channel]_channel_spec.rb.
        # delayed_jobs = Delayed::Job.all
        # expect(delayed_jobs.count).to be > 0

        change_set = ChangeSet.last
        expect(change_set.type).to eq('MasterRateChangeSet')
      end

      it 'should handle errors gracefully' do
      end
    end
  end