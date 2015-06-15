# Returned xml from OTA must be adjusted to have the structure
# similar to this class
class RoomTypeXml
  attr_accessor :id # room type id (RoomType in Agoda, RatePlan in Ctrip, etc.)
  attr_accessor :name # room type id
  attr_accessor :rate_type_id # (RatePlan in Agoda, RatePlanCategory in Ctrip, etc.)
  attr_accessor :rate_type_name
  attr_accessor :room_type_content # returned xml from room type fetcher
  attr_accessor :rate_type_content # returned xml from rate type fetcher

  def initialize(id, name, rate_type_id, rate_type_name, room_type_content, rate_type_content)
    @id = id
    @name = name
    @rate_type_id = rate_type_id
    @rate_type_name = rate_type_name
    @room_type_content = room_type_content
    @rate_type_content = rate_type_content
  end
  
end

