require 'active_record/fixtures'

def run
  print "Running db/seeds.rb...\n"

  # Do not import seeds.sql if environment is production.
  if RAILS_ENV == 'production'
    print "We don't want to reimport seeds.sql into production, so skip this step and move on.\n"
    production_seeds
  else
    connection = ActiveRecord::Base.connection
    connection.tables.each do |table|
      connection.execute("TRUNCATE #{table}") unless table == "schema_migrations"
    end

    # - IMPORTANT: SEED DATA ONLY
    # - DO NOT EXPORT TABLE STRUCTURES
    # - DO NOT EXPORT DATA FROM `schema_migrations`
    print "Importing from db/seeds.sql...\n"
    sql = File.read("#{Rails.root}/db/seeds.sql")
    statements = sql.split(/;/)
    print "Found #{statements.count} queries.\n"
    statements.pop  # the last empty statement

    ActiveRecord::Base.transaction do
      statements.each do |statement|
        connection.execute(statement.strip)
      end
    end

    production_seeds
    development_seeds
  end

  print "Seed data imported!\n"
end
#---------------------------------

# Seed data required for production as well.
def production_seeds
  # Super Admin members creation
  #---------------------------------
  admin_account = Account.where(:name => 'Plaza Hotel Glodok').first
  property_ids = Property.all(:select => :id, :conditions => {:approved => 1}).collect(&:id)

  super_admins = [
    {
      :name => 'Jay',
      :email => 'jay@chanelink.com',
      :password => 'Passw0rd'
    },
    {
      :name => 'Theo',
      :email => 'theodorems@chanelink.com',
      :password => 'Passw0rd'
    }
  ]

  super_admins.each do |admin|
    # For front end
    if !Member.find_by_email(admin[:email])
      super_admin = Member.create do |m|
        m.name = admin[:name]
        m.email = admin[:email]
        m.password = admin[:password]
        m.disabled = false
        m.account = admin_account
        m.assigned_properties = property_ids
        m.master = 1
        m.role = MemberRole.where(:type => 'SuperRole').first
      end

      super_admin.skip_properties_validation = true
      super_admin.update_attributes(:password => admin[:password], :prompt_password_change => false)
    end

    # For back end
    if !User.find_by_email(admin[:email])
      super_admin = User.create do |u|
        u.name = admin[:name]
        u.email = admin[:email]
        u.password = admin[:password]
        u.super = 1
      end
      super_admin.skip_properties_validation = true
      super_admin.update_attributes(:password => admin[:password], :prompt_password_change => false)
    end
  end

  channels = [
    {
      :name => 'Ctrip',
      :type => 'CtripChannel'
    },
    {
      :name => 'GtaTravel',
      :type => 'GtaTravelChannel'
    },
    {
      :name => 'Orbitz',
      :type => 'OrbitzChannel'
    },
    {
      :name => 'Tiketcom',
      :type => 'TiketcomChannel'
    }
  ]
  channels.each do |channel|
    if !Channel.find_by_name(channel[:name])
      ctrip = Channel.create do |c|
        c.name = channel[:name]
        c.type = channel[:type]
      end
    end
  end
end

#---------------------------------

# Seed data used only for development.
# You may add any sample data here.
def development_seeds
  # Lets use Plaza Hotel Glodok as our sample account.
  property = Property.first(:conditions => {:name => 'Plaza Hotel Glodok'})
  property.settings(:ctrip_hotel_id) = '54394'
  property.settings(:ctrip_username) = '54394'
  property.settings(:ctrip_password) = '123qaz'
  property.settings(:ctrip_code_context) = '4085'
  pool = Pool.first(:conditions => {:property_id => property.id, :name => 'OTA'})
  ctrip = Channel.first(:conditions => {:name => 'Ctrip'})
  property_channels = [
    {
        :property => property,
        :pool => pool,
        :channel => ctrip,
        :approved => 1,
        :disabled => 0
    }
  ]
  property_channels.each do |property_channel|
    if !PropertyChannel.first(:conditions => {:property_id => property.id, :channel_id => ctrip.id, :pool_id => pool.id})
      ctrip_on_plaza_hotel_glodok = PropertyChannel.create do |pc|
        pc.property = property_channel[:property]
        pc.pool = property_channel[:pool]
        pc.channel = property_channel[:channel]
        pc.settings = property_channel[:settings]
        pc.approved = property_channel[:approved]
        pc.disabled = property_channel[:disabled]
      end
    end
  end
end

# test data do not need seed, obviously. They are set up in test/fixtures.

run
# Consult release_notes.md for upgrading migrations.