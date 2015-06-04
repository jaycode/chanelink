require 'rails_helper'

describe 'AgodaChannel', :type => :model do
# 	scenario 'testing connection' do
# 		request_xml = '<?xml version="1.0" encoding="utf-8" ?>
# <GetHotelInventoryRequest xmlns="http://xml.ycs.agoda.com">
# <Authentication APIKey="' + AgodaChannel::API_KEY + '" HotelID="'+properties(:big_hotel_1).agoda_hotel_id+'"/>
# <RoomType RoomTypeID="' + room_type_channel_mappings(:superior_agoda).agoda_room_type_id + '" RatePlanID="22"/>
# <DateRange Type="Stay" Start="2012-01-01" End="2012-01-31"/>
# <RequestedLanguage>en</RequestedLanguage>
# </GetHotelInventoryRequest>'
# 		response = AgodaChannel.post_xml(request_xml)
# 		puts '============'
# 		puts response
# 		puts '============'
# 	end

	scenario 'room type fetcher' do
		channel = AgodaChannel.first
		room_types = channel.room_type_fetcher.retrieve(properties(:big_hotel_1))
		puts '============'
		puts YAML::dump(room_types)
		puts '============'
		# ============
		# ---
		# - !ruby/object:AgodaRoomTypeXml
		#   id: '827875'
		#   name: Deluxe
		# - !ruby/object:AgodaRoomTypeXml
		#   id: '827874'
		#   name: Superior
		# ============
		expect(room_types.count).to be > 0
	end

	scenario 'get room availabilities' do
	end

	scenario 'editing master rate' do
		# existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(
		# 	today,
		# 	current_property.id,
		# 	params[:pool_id], rt.id
		# )
	end
end