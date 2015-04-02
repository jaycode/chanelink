# pre cache assets
require 'jammit'

namespace :utility  do
  desc "This task will cache assets using jammit"
  task :jammit_precache_assets => :environment do    
    Jammit.package!
  end
end