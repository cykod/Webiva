require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe UserProfile::AdminController do
  reset_domain_tables :user_profile_types, :configurations, :site_modules

  before(:each) do
    test_activate_module('user_profile')
  end

  it 'should create default profile type on mod set up' do
    mock_editor
    assert_difference "UserProfileType.count", 1 do
      get "options"
    end
  end

end
