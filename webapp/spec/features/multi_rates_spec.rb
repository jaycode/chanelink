require 'rails_helper'
require 'connectors/connector'
require 'connectors/agoda_connector'
require 'connectors/ctrip_connector'

describe 'Multi Rates Spec' do
  include IntegrationTestHelper
  include Capybara::DSL
  before(:each) do
    member = members(:super_admin)
    login member.email, 'testpass'
    @property = properties(:big_hotel_1)
    select_property @property.id
    @pool = pools(:default_big_hotel_1)
  end

  scenario 'Property Channel edit page must show unmapped rooms' do
    visit "property_channels/#{property_channels(:master_rate_mappings_tester_agoda).id}/edit"
    expect(all(:css, ".property_rooms-unmapped-item").count).to eq(2)
  end

  scenario 'Property Channel creation should allow linking to room and rate types.' do
    property_channel = property_channels(:big_hotel_1_default_agoda)
    room_type = room_types(:unassigned)
    channel = channels(:agoda)

    visit "/room_type_channel_mappings/new?property_channel_id=#{property_channel.id}&room_type_id=#{room_type.id}"
    save_and_open_page
    first_option = find(:css, "#room_type_channel_mapping_ota_room_type_id option:nth-child(1)")
    room_types = channel.room_type_fetcher.retrieve(properties(:big_hotel_1), false)

    # In default, passed value must contain room type and rate type ids.
    expect(first_option.value).to eq("#{room_types[0].id}:#{room_types[0].rate_type_id}")

    puts "Option to choose: #{room_types[1].id}:#{room_types[1].rate_type_id}."

    # This is how to select option by value:
    within '#room_type_channel_mapping_ota_room_type_id' do
      find("option[value='#{room_types[1].id}:#{room_types[1].rate_type_id}']").select_option
    end

    click_button('room_type_channel_mapping_submit')
    fill_in('room_type_channel_mapping_agoda_single_rate_multiplier', :with => 1)
    click_button('room_type_channel_mapping_submit')
    save_and_open_page
    choose("room_type_channel_mapping_rate_configuration_master_rate")
    click_button('room_type_channel_mapping_submit') # Must click this button to show inputs since javascript isn't working.
    select("Superior", :from => 'room_type_master_rate_channel_mapping_room_type_master_rate_mapping_id')
    fill_in("room_type_master_rate_channel_mapping_percentage", :with => 100)
    click_button('room_type_channel_mapping_submit')
    check("room_type_channel_mapping_enabled")
    click_button('room_type_channel_mapping_submit')

    # save_and_open_page
    expect(RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(
             room_type.id, channel.id).ota_room_type_id).to eq(room_types[1].id)
    expect(RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(
             room_type.id, channel.id).ota_rate_type_id).to eq(room_types[1].rate_type_id)
  end

  scenario 'Updating master rates from inventory grid.' do
    Begin by removing rate_type association from a room_type_master_rate_channel_mapping
    mapping = room_type_master_rate_channel_mappings(:default_big_hotel_1_pool_to_superior_room_in_agoda)

    visit "/inventories?pool_id=#{@pool.id}"
    save_and_open_page
    # Expect that page to contain offer to update Agoda rate types.
    expect(page).to contain("No rate type mapped")
  end

  # scenario 'All property channels must be assigned with default rate type when they are first created' do
  #   # Go to property channel creation page, create a property_channel, then see if created property channel
  #   # was assigned with default rate.
  #   visit "/inventories?pool_id=#{@pool_id}"
  # end

  scenario 'Master rates should show multiple rate types in Inventory Grid.' do
  end

  scenario 'Channel rates should show multiple rate types in Inventory Grid.' do
  end

  scenario 'An account can add custom rate plans and assign them to channel rate plans' do
  end

  private

  def erase_room_type_master_rate_mapping_id
    mapping = RoomTypeMasterRateChannelMapping.first(:conditions => {
                                                       :room_type_master_rate_mapping_id => room_type_master_rate_mappings(:default_big_hotel_1_pool_to_superior_room).id,
                                                       :channel_id => channels(:agoda).id
                                                     })
    mapping.rate_type_id = nil
    mapping.save
    expect(mapping.valid?).to eq(true)
    mapping = RoomTypeMasterRateChannelMapping.first(:conditions => {
                                                       :room_type_master_rate_mapping_id => room_type_master_rate_mappings(:default_big_hotel_1_pool_to_superior_room).id,
                                                       :channel_id => channels(:agoda).id
                                                     })

    expect(mapping.rate_type_id).to be_nil
  end

end