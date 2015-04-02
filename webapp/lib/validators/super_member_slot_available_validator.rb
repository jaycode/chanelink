# To change this template, choose Tools | Templates
# and open the template in the editor.

class SuperMemberSlotAvailableValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if Member.find_all_by_account_id_and_role_id(record.account_id, MemberRole.super_role.id).count >= Member::MAXIMUM_SUPER
      record.errors[I18n.t("members.create.message.account")] << (options[:message] || I18n.t("members.create.message.maximum_slot_super", :account => Account.find(record.account_id).name, :maximum => Member::MAXIMUM_SUPER))
    end
  end
end
