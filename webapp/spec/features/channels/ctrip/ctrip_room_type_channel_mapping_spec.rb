require 'rails_helper'

describe 'Ctrip Room Type Channel Mapping Spec', :type => :feature do
  include IntegrationTestHelper
  include Capybara::DSL
  describe 'Great Success!' do
    before(:each) do
      member = members(:super_admin)
      login member.email, 'testpass'
      property = properties(:big_hotel_1)
      select_property property.id
      @property_channel = property_channels(:big_hotel_1_default_ctrip)
      @room_type = room_types(:unassigned)
      @channel = channels(:ctrip)
    end

    scenario "Mapping a Chanelink's room to OTA's" do
      visit "/room_type_channel_mappings/new?property_channel_id=#{@property_channel.id}&room_type_id=#{@room_type.id}"
      first_option = find(:css, "#room_type_channel_mapping_ctrip_room_rate_plan_code option:nth-child(1)")
      room_types = @channel.room_type_fetcher.retrieve(properties(:big_hotel_1), false, '2015-02-23', '2015-02-25')

      # For Ctrip, rate plan code must contain category.
      expect(first_option.value).to eq("#{room_types[0].id}:#{room_types[0].rate_plan_category}")

      puts "Option to choose: #{room_types[1].id}:#{room_types[1].rate_plan_category}."
      
      # This is how to select option by value:
      within '#room_type_channel_mapping_ctrip_room_rate_plan_code' do
        find("option[value='#{room_types[1].id}:#{room_types[1].rate_plan_category}']").select_option
      end

      click_button('room_type_channel_mapping_submit')
      click_button('room_type_channel_mapping_submit')
      choose("room_type_channel_mapping_rate_configuration_master_rate")
      click_button('room_type_channel_mapping_submit') # Must click this button to show inputs since javascript isn't working.
      select("Superior", :from => 'room_type_master_rate_channel_mapping_room_type_master_rate_mapping_id')
      fill_in("room_type_master_rate_channel_mapping_percentage", :with => 100)
      click_button('room_type_channel_mapping_submit')
      check("room_type_channel_mapping_enabled")
      click_button('room_type_channel_mapping_submit')

      # save_and_open_page
      expect(RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(
        @room_type.id, @channel.id).room_type_id).to eq(room_types[1].id)
      expect(RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(
        @room_type.id, @channel.id).rate_type_property_channel.ota_rate_type_id).to eq(room_types[1].rate_plan_category)

    end

  end

  # This doesn't work, as somehow validates_uniqueness_of :room_type_id, :scope => :channel_id, :if => Proc.new { |ex| !ex.deleted}
  # still not allowing uniqueness even when field deleted.

  # describe 'Room Type already taken' do
  #     before(:each) do
  #     member = members(:super_admin)
  #     login member.email, 'testpass'
  #     property = properties(:big_hotel_1)
  #     select_property property.id
  #     @property_channel = property_channels(:big_hotel_1_default_ctrip)
  #     @room_type = room_types(:superior)
  #     @channel = channels(:ctrip)
  #   end

  #   scenario "Mapping a Chanelink's room to OTA's" do
  #     visit "/room_type_channel_mappings/new?property_channel_id=#{@property_channel.id}&room_type_id=#{@room_type.id}"
  #     first_option = find(:css, "#room_type_channel_mapping_ctrip_room_rate_plan_code option:nth-child(1)")
  #     room_types = @channel.room_type_fetcher.retrieve(properties(:big_hotel_1), false, '2015-02-23', '2015-02-25')

  #     # For Ctrip, rate plan code must contain category.
  #     expect(first_option.value).to eq("#{room_types[0].id}:#{room_types[0].rate_plan_category}")

  #     find("#room_type_channel_mapping_ctrip_room_rate_plan_code option[value='#{room_types[1].id}:#{room_types[1].rate_plan_category}']").click
  #     click_button('room_type_channel_mapping_submit')
  #     click_button('room_type_channel_mapping_submit')
  #     expect(page).to have_content('Room type has already been taken')
  #   end

  # end
end