# class to control ability of backoffice user
class AdminAbility
  include CanCan::Ability

  def initialize(user)

    return false if user.blank?

    if user.super?
      can :manage, :all
    else
      can :manage, :all
      cannot :delete, Account
      cannot :delete, Member
      cannot :delete, Property
      cannot :delete, RoomTypeChannelMapping
      cannot :delete, RoomType
      cannot :delete, User
      cannot :index, User
    end
  end
end