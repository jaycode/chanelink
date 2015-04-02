require 'test_helper'

class MemberTest < ActiveSupport::TestCase
  test "admin member creation" do
    member = Member.create do |m|
      m.name = "Super Admin"
      m.email = "superadmin@chanelink.com"
      m.disabled = false
    end
    assert member.valid?
  end
end
