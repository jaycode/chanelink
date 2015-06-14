class Connector
  attr_reader :property

  def initialize(property)
    @property = property
  end

  def set_property(property)
    @property = property
  end
end