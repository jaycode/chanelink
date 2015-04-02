class GtaTravelRoomTypeXml
  attr_reader :id
  attr_reader :name
  attr_reader :rate_basis
  attr_reader :max_occupancy

  def self.all
    # do nothing
  end

  def self.find(param)
    # do nothing
  end

  def initialize(id, name, rate_basis, max_occupancy)
    @id = id
    @name = name
    @rate_basis = rate_basis
    @max_occupancy = max_occupancy
  end
  
end

