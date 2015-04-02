class CreateUserLogins < ActiveRecord::Migration
  def self.up
    create_table :user_logins do |t|
      t.belongs_to :user
      t.boolean :success
      t.timestamps
    end
  end

  def self.down
    drop_table :user_logins
  end
end
