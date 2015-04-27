require 'rails_helper'

describe 'Member', :type => :model do
	scenario 'admin member creation' do
		# Account is the main account a member belongs to.
		# One account can have many hotels i.e. properties in our term.
		admin_account = accounts(:big_hotel_chain) # This is an example of how we can use Rails fixtures to reference a data point.

		# This is one among many ways to query data in Ruby on Rails.
		# Search for "rails collect" in Google to find out what it does.
		property_ids = Property.all(:conditions => {:approved => 1}).collect(&:id)

		# "puts" in rails is the equivalent of "echo" in php.
		# Array.inspect is the equivalent of "print_r" in php.
		# puts property_ids.inspect

		# This is how you create a new model.
		# My way to develop is by writing test code to
		# create test data, then copy the creation code into seeds.rb
		# but with development data as building blocks.
		# (May not be the perfect method but it worked for me...)
		email = 'testadmin@chanelink.com'
		pass = 'Passw0rd'
		member = Member.create do |m|
			m.name = 'Test Admin'
			m.email = email
			m.disabled = false
			m.password = pass
			m.account = admin_account
			m.assigned_properties = property_ids
			m.master = 1
			m.role = member_roles(:super)
		end
		# You may also use:
		# member = Member.new do |m|
		#   ...set m properties here...
		# end
		# member.save

		assert member.valid?, 'Member not created, errors: #{member.errors.full_messages}'

		# Try logging in with this newly created member.
		session = ActionController::TestSession.new()
		logged_in_member = Member.authenticate(email, pass, session)
		assert_nil(logged_in_member)

		# From doing this test (and another one at functional/sessions_controller_test.rb) 
		# we know for sure that turns out, for new member,
		# password is automatically generated, so it was useless to set password
		# during member creation above.
		# In here we will reset the password again.

		# todo: For now we get code pieces from members_container to do so
		#       but I would expect some refactor here later e.g. skip_properties_validation
		#       should not be needed.
		member.skip_properties_validation = true
		member.update_attributes(:password => pass, :prompt_password_change => false)

		# Let's try logging in again.
		session = ActionController::TestSession.new()
		logged_in_member = Member.authenticate(email, pass, session)
		assert_not_nil(logged_in_member)
		assert_equal(email, logged_in_member.email)
	end

	scenario 'member login' do
		# Let's try something else.
		# In this method we will try to login with a member account
		# as stored in fixture members.yml.
		#
		# Remember that each test method is run independently from each other,
		# and they are being run in alphabetic order. That is why we need to
		# recreate the member in fixture instead of running "member login" after
		# "admin member creation" method.
		email = 'jay@chanelink.com'
		pass = 'testpass'
		# Found from searching for "session" in Rails' Github repo:
		# https://github.com/rails/rails/tree/3-0-stable
		session = ActionController::TestSession.new()

		member = Member.authenticate(email, pass, session)

		assert_equal(email, member.email)
	end
	# From here, you may want to see functional/sessions_controller_test.rb
	# to learn about functional testing and how to test logging into the app
	# from controller.
end