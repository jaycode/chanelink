class CreateMemberRoles < ActiveRecord::Migration
  def self.up
    create_table :member_roles do |t|
      t.string :type
      t.timestamps
    end

    SuperRole.create
    ConfigRole.create
    GeneralRole.create
  end

  def self.down
    drop_table :member_roles
  end
end
