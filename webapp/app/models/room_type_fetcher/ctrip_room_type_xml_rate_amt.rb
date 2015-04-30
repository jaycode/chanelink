class CtripRoomTypeXmlRateAmt
  attr_reader :amount_after_tax
  attr_reader :currency_code
  attr_reader :code

  def self.all
    # do nothing
  end

  def self.find(param)
    # do nothing
  end

  def initialize(amount_after_tax, currency_code, code)
    @amount_after_tax = amount_after_tax
    @currency_code    = currency_code
    @code             = code
  end
  
end

