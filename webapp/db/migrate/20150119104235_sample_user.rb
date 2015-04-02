require 'active_record/fixtures'

class SampleUser < ActiveRecord::Migration
  def self.up
    down()

    directory = File.join(File.dirname(__FILE__), "init_data")
    Fixtures.create_fixtures(directory, "profiles")
  end

  def self.down
    Profile.delete_all
  end
end