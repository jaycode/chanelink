# represent a change set (everytime member click submit button on inventory grid)
class ChangeSet < ActiveRecord::Base

  has_many :change_set_channels

  def run
    # do nothing, to be implemented by sub class
  end

  # get unique room types in all this room set
  def room_type_ids
    # do nothing, to be implemented by sub class
  end

  def pool
    # do nothing, to be implemented by sub class
  end

  # grouped logs by room type id
  def self.organize_logs_by_room_type_id(change_set)
    logs = change_set.logs
    room_type_ids = change_set.room_type_ids
    result = Hash.new
    room_type_ids.each do |rt_id|
      rt_logs = Array.new
      logs.each do |inv_log|
        rt_logs << inv_log if inv_log.inventory.room_type.id == rt_id
      end
      result[rt_id] = rt_logs
    end
    result
  end
  
end
