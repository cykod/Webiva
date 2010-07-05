require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

describe UserProfileEntry do

  reset_domain_tables :content_publications, :content_publication_fields, :user_profile_types, :content_model_features, :user_profile_entries, :end_users, :user_profile_type_user_classes, :content_nodes, :content_types, :site_modules

  before do
    test_activate_module('user_profile')
    @prof_type =  UserProfileType.create(:name => 'Test',
                                          :user_classes => [ { 'id' =>  UserClass.default_user_class_id } ])
  end

  after do
    SiteModule.destroy_all
  end

  it 'should create entries' do
    assert_difference "UserProfileEntry.count", 2 do 
      EndUser.push_target('test@webiva.org')
      EndUser.push_target('test2@webiva.org')
    end
  end


  it 'should delete profile entries when the type is deleted' do
    EndUser.push_target('test@webiva.org')
    assert_difference "UserProfileEntry.count", -1 do
     @prof_type.destroy
    end
  end

end
