# class used to determine access/credentials for super, config and general member
class Ability
  include CanCan::Ability

  def initialize(member, property)
    return false if member.blank?

    # super can manage all
    if member.super_member?
      can :manage, :all
    # define access ability for config
    elsif member.config_member?

      can :read, Property
      can :select, Property
      can :do_select, Property
      can :show_embed, Property
      can :no_registered_property, Property

      can :tool, CopyTool
      can :submit, CopyTool

      can :manage, RoomType

      can :read, RoomTypeInventoryLink
      can :read, RoomTypeMasterRateMapping
      can :read, RoomTypeMasterRateChannelMapping

      can :update, PropertyChannel
      can :read, PropertyChannel

      can :manage, RoomTypeChannelMapping

      can :update, Pool
      can :delete, Pool

      can :prompt_password, Member
      can :prompt_password_set, Member

      can :show, CurrencyConversion
    # define access ability for general
    elsif member.general_member?
      can :read, Property
      can :select, Property
      can :do_select, Property
      can :show_embed, Property
      can :no_registered_property, Property

      can :read, RoomType
      can :index, RoomType

      can :read, RoomTypeInventoryLink
      can :read, RoomTypeMasterRateMapping
      can :read, RoomTypeMasterRateChannelMapping

      can :read, PropertyChannel

      can :read, RoomTypeChannelMapping

      can :update, Pool
      can :delete, Pool

      can :prompt_password, Member
      can :prompt_password_set, Member

      can :show, CurrencyConversion
      
    end
  end
end