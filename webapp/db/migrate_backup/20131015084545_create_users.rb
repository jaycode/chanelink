class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :email_validation_key
      t.string :hashed_password
      t.string :reset_password_key
      t.string :salt
      t.timestamps
    end

    add_index(:users, :id, :unique => true)

    User.create(:name => 'Admin', :email => 'admin@chanelink.com', :password => 'chanelink')
  end

  def self.down
    drop_table :users
  end
end
