module IntegrationTestHelper
  def login(sess, member_fixture_key)
    puts "inside integration test helper login method"
    member = members(member_fixture_key)
    puts "member: #{member.inspect}"
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