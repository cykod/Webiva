
require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

describe UserProfileType do

  reset_domain_tables :content_publications, :content_publication_fields, :user_profile_types, :content_model_features, :end_users

  before(:each) do
    @cm = ContentModel.find(:first)
    @prof_type =  UserProfileType.create(:name => "Test profile type default",
                                         :user_classes => [ { 'id' => UserClass.default_user_class_id.to_s } ])
  end

  after do
    SiteModule.destroy_all
  end

  specify {@prof_type.should be_valid}
end

