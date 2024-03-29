# represent inventory record
# Todo: property is not needed since pool already contains it
class Inventory < ActiveRecord::Base

  extend Unscoped

  belongs_to :property
  belongs_to :room_type
  belongs_to :pool

  unscope :property, :room_type, :pool
end
