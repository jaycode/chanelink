class CtripRoomTypeXmlRate
  attr_reader :start_date
  attr_reader :end_date
  attr_reader :number_of_units
  attr_reader :status
  attr_reader :base_by_guest_amts

  def self.all
    # do nothing
  end

  def self.find(param)
    # do nothing
  end

  def initialize(start_date, end_date, number_of_units, status, base_by_guest_amts)
    @start_date         = start_date
    @end_date           = end_date
    @number_of_units    = number_of_units
    @status             = status
    @base_by_guest_amts = base_by_guest_amts
  end
  
end

