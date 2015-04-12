module IntegrationTestHelper
  module Rails
    def login(sess, member_fixture_key)
      member = members(member_fixture_key)
      sess.https!
      sess.post '/session',
        :email => member.email,
        :password => 'testpass'
    end

    def select_property(sess, property_fixture_key)
      sess.https!
      sess.get '/properties/do_select',
        :property_id => properties(property_fixture_key).id
    end
  end
  module Capybara
    def login(email, pass)
      visit '/session/new'
      # print page.html
      fill_in 'email', :with => email
      fill_in 'password', :with => pass
      click_button 'Login'
    end

    def select_property(property_id)
      visit "/properties/do_select?property_id=#{property_id}"
    end

    def login_backend(email, pass)
      visit '/backoffic3'
      fill_in 'email', :with => email
      fill_in 'password', :with => pass
      click_button 'Login'
    end

    def select_property_backend(property_id)
      visit "/backoffic3/select_property_set?id=#{property_id}"
    end
  end
end