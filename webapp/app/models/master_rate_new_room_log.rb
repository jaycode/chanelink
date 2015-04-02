# represent history log of master rate because of new room
class MasterRateNewRoomLog < ActiveRecord::Base

  belongs_to :master_rate

  def self.create_master_rate_new_room_log(master_rate)
    MasterRateNewRoomLog.create(:master_rate_id => master_rate.id, :amount => master_rate.amount)
  end

end
