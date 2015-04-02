class CreateUserPropertyAccesses < ActiveRecord::Migration
  def self.up
    create_table :user_property_accesses do |t|
      t.belongs_to :user
      t.belongs_to :property
      t.timestamps
    end
  end

  def self.down
    drop_table :user_property_accesses
  end
end
