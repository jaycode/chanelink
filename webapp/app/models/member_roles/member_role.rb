# class that represent member role
class MemberRole < ActiveRecord::Base

  def cname
    # do nothing
  end

  def self.super_role
    SuperRole.first
  end

  def self.config_role
    ConfigRole.first
  end

  def self.general_role
    GeneralRole.first
  end

  # list all role to be used for UI
  def self.select_list
    result = Array.new
    all_types = [general_role, config_role, super_role]
    all_types.each do |mt|
      result << [I18n.t("roles.type.#{mt.cname}"), mt.id]
    end
    result
  end

end