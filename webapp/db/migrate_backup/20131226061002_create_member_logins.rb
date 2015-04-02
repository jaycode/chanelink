class CreateMemberLogins < ActiveRecord::Migration
  def self.up
    create_table :member_logins do |t|
      t.belongs_to :member
      t.boolean :success
      t.timestamps
    end
  end

  def self.down
    drop_table :member_logins
  end
end
