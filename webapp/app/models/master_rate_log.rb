# represent history log for master rate record
class MasterRateLog < ActiveRecord::Base

  belongs_to :master_rate

  # helper to create new log
  def self.create_master_rate_log(master_rate)
    MasterRateLog.create(:master_rate_id => master_rate.id, :amount => master_rate.amount)
  end

end
