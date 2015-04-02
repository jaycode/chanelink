# represent a currency
class Currency < ActiveRecord::Base

  # list of currency with disabled option
  def self.currency_list_with_disable
    result = Array.new
    result << [I18n.t("currency_conversion.index.label.disable"), nil]
    Currency.all.each do |currency|
      result << ["#{currency.code} - #{currency.name}", currency.id]
    end
    result
  end

  # list of currency with prompt
  def self.currency_list_with_prompt
    result = Array.new
    result << [I18n.t("currency_conversion.index.label.placeholder"), nil]
    Currency.all.each do |currency|
      result << ["#{currency.code} - #{currency.name}", currency.id]
    end
    result
  end

end
