# class to hold information of returned rate type xml.
class RateTypeXml
  attr_accessor :id
  attr_accessor :name
  attr_accessor :content

  def initialize(id, name, response_str = nil)
    @id = id
    @name = name
    unless response_str.nil?
      @content = Hash.from_xml(response_str)
    end
  end
  
end

