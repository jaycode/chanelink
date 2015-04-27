require 'rails_helper'

describe 'AgodaChannel', :type => :model do
	scenario 'room type fetcher' do
		channel = AgodaChannel.first
		room_types = channel.room_type_fetcher.retrieve(properties(:big_hotel_1))
		assert room_types.count > 0
	end

	scenario 'inventory handler' do
		channel = AgodaChannel.first

	end

	scenario 'editing master rate' do
		# existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(
		# 	today,
		# 	current_property.id,
		# 	params[:pool_id], rt.id
		# )
	end
end