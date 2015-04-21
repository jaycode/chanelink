module IntegrationTestHelper
  module WithRails
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
  module WithCapybara
    def login(email, pass)
      unless logged_in?
        visit '/session/new'
        # print page.html
        fill_in 'email', :with => email
        fill_in 'password', :with => pass
        click_button 'Login'
      end
    end

    def select_property(property_id)
      visit "/properties/do_select?property_id=#{property_id}"
    end

    def login_backend(email, pass)
      unless backend_logged_in?
        visit '/backoffic3'
        fill_in 'email', :with => email
        fill_in 'password', :with => pass
        click_button 'Login'
      end
    end

    def select_property_backend(property_id)
      visit "/backoffic3/select_property_set?id=#{property_id}"
    end
    def logged_in?
      begin
        cookies = Capybara.current_session.driver.request.cookies
        puts "has key?"
        if cookies.has_key?('member_chanelink_auth')
          puts 'yep'
          true
        else
          puts 'nope'
          false
        end
      rescue
        false
      end
    end
    def backend_logged_in?
      begin
        cookies = Capybara.current_session.driver.request.cookies
        if cookies.has_key?('user_chanelink_auth')
          true
        else
          false
        end
      rescue
        false
      end
    end
  end
end