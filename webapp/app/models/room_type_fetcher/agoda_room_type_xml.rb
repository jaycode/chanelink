# class to hold information of agoda room type
class AgodaRoomTypeXml
  attr_reader :id
  attr_reader :name

  def self.all
    # do nothing
  end

  def self.find(param)
    # do nothing
  end

  def initialize(id, name)
    @id = id
    @name = name
  end
  
end

