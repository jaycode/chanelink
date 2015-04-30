class CtripRoomTypeXml
  attr_reader :name
  attr_reader :rate_plan_category
  attr_reader :id
  attr_reader :rates

  def self.all
    # do nothing
  end

  def self.find(param)
    # do nothing
  end

  def initialize(id, name, rate_plan_category, rates)
    @id                 = id
    @name               = name
    @rate_plan_category = rate_plan_category
    @rates              = rates
  end
  
end

