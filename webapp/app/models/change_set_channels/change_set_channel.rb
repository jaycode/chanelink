# represent what needs to be done to a channel because of a change set
class ChangeSetChannel < ActiveRecord::Base

  belongs_to :change_set
  belongs_to :channel
  belongs_to :room_type

  def run
    # do nothing, to be overridden by subclass
  end
  
end
