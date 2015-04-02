class CtripRoomTypeXml
  attr_reader :name
  attr_reader :rate_plan_category
  attr_reader :id

  def self.all
    # do nothing
  end

  def self.find(param)
    # do nothing
  end

  def initialize(id, name, rate_plan_category)
    @id = id
    @name = name
    @rate_plan_category = rate_plan_category
  end
  
end

