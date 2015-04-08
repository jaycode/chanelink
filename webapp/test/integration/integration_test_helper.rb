module IntegrationTestHelper
  def login(sess, member_fixture_key)
    puts "inside integration test helper login method"
    member = members(member_fixture_key)
    puts "member: #{member.inspect}"
    puts "path to go to: #{url_for(:controller => 'sessions', :action => :create)}"
    sess.post(url_for(:controller => 'sessions', :action => :create), {
      :email => member[:email],
      :password => member[:password]
    })
  end

  def select_property(sess, property_fixture_key)
    sess.get(url_for(:controller => 'properties', :action => 'select'), {
      :property_id => properties(property_fixture_key).id
    })
  end
end