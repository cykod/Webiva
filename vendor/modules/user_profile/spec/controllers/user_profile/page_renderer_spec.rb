require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe UserProfile::PageRenderer, :type => :controller do
  
  controller_name :page

  integrate_views
  reset_domain_tables :user_profile_types, :user_profile_entries, :content_types, :end_users, :user_profile_type_user_classes


  before do
    test_activate_module('user_profile')
    @prof_type =  UserProfileType.create(:name => "Test profile type default",
                                          :user_classes => [ { 'id' => UserClass.default_user_class_id.to_s } ])
    @usr = EndUser.push_target("tester@webiva.org",:name => 'Svend Karlson')
  end

  renderer_builder '/user_profile/page/display_profile'

  it "should be able to display the profile page" do
    @rnd = display_profile_renderer({:profile_type_id => @prof_type.id},:user_profile => [:url,'svend-karlson'])
    renderer_get @rnd
    response.should include_text('Svend Karlson')
  end

  it "shouldn't display display an invalid profile" do
    @rnd = display_profile_renderer({:profile_type_id => @prof_type.id},:user_profile => [:url,'testerama'])
    renderer_get @rnd
    response.should include_text('no profile exists')
  end
  
end

