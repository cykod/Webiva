
class TestTarget
  attr_accessor :id
end

module FeedbackTestHelper
  def create_end_user(email='test@webiva.com', options={:first_name => 'Test', :last_name => 'User'})
    EndUser.push_target(email, options)
  end
end
