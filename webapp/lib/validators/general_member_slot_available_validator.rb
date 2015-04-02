# To change this template, choose Tools | Templates
# and open the template in the editor.

class GeneralMemberSlotAvailableValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if !value.blank?
      value.each do |property_id|
        all_generals = Member.find_all_by_account_id_and_role_id(record.account_id, MemberRole.general_role.id).collect(&:id)
        if MemberPropertyAccess.member_ids(all_generals).where(:property_id => property_id).count >= Member::MAXIMUM_GENERAL_PER_PROPERTY
          record.errors[I18n.t("members.create.message.hotel")] << (options[:message] || I18n.t("members.create.message.maximum_slot_general", :property => Property.active_only.find(property_id).name, :maximum => Member::MAXIMUM_GENERAL_PER_PROPERTY))
        end
      end
    end
  end
end
