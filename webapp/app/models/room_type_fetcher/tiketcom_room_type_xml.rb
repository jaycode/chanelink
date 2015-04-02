class ExpediaRoomTypeXml
  attr_reader :id
  attr_reader :name
  attr_reader :rate_plan_id

  def self.all
    # do nothing
  end

  def self.find(param)
    # do nothing
  end

  def initialize(id, name, rate_plan_id)
    @id = id
    @name = name
    @rate_plan_id = rate_plan_id
  end
  
end

