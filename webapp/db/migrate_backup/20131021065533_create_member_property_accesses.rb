class CreateMemberPropertyAccesses < ActiveRecord::Migration
  def self.up
    create_table :member_property_accesses do |t|
      t.belongs_to :member
      t.belongs_to :property
      t.timestamps
    end
  end

  def self.down
    drop_table :member_property_accesses
  end
end
