class InventoryXml
  attr_accessor :room_type_id

  # In Expedia, make sure to set "rates" to true.
  attr_accessor :rate_type_id

  attr_accessor :date
  attr_accessor :total_rooms

  def initialize args
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end
end