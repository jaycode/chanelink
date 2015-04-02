# To change this template, choose Tools | Templates
# and open the template in the editor.

class StrictPasswordValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if !value.blank?
      downcase = value.downcase
      if value != downcase and value =~ /\d/
        # do nothing
      else
        record.errors[attribute] << (options[:message] || I18n.t("members.prompt_password.message.invalid_password"))
      end
    end
  end
end
