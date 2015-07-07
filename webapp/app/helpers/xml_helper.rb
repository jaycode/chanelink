module XmlHelper

  # Sometimes element.value changes to element
  def get_element_value(element)
    if element.kind_of? String
      element
    else
      element.value
    end
  end

end
