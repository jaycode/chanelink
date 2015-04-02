# represent a country record
class Country < ActiveRecord::Base

  # list of country to be used by UI
  def self.select_list
    result = Array.new
    result << [I18n.t('admin.properties.new.label.country_placeholder'), nil]
    Country.order(:name).each do |country|
      result << [country.name, country.id]
    end
    result
  end
  
end
