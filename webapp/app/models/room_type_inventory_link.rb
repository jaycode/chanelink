# represent availability linking record
class RoomTypeInventoryLink < ActiveRecord::Base

  extend Unscoped

  default_scope lambda {{ :conditions => ["deleted = ?", false] }}

  belongs_to :property
  belongs_to :room_type_from, :class_name => "RoomType", :foreign_key => 'room_type_from_id'
  belongs_to :room_type_to, :class_name => "RoomType", :foreign_key => 'room_type_to_id'

  unscope :property

  validates :property, :presence => true
  validates :room_type_from, :presence => true
  validates :room_type_to, :presence => true

  # return room type not availability linked
  def self.room_not_linked?(property)
    result = false
    # check each property room types
    property.room_types.each do |rt|
      if RoomTypeInventoryLink.find_by_room_type_from_id(rt.id).blank?
        result = true
      end
    end
    result
  end

  # all room type linked in a property
  def self.select_list(property, room_type)
    result = Array.new
    result << [I18n.t('room_type_inventory_links.placeholder'), nil]
    property.room_types.each do |rt|
      if room_type != rt and !rt.is_inventory_linked?
        result << [rt.name, rt.id]
      end
    end
    result
  end

end
