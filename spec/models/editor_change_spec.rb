require File.dirname(__FILE__) + "/../spec_helper"

describe EditorChange do

  reset_domain_tables :editor_changes, :end_users, :site_feature
  
  before(:each) do
    @change = EditorChange.new
    @admin_user = EndUser.push_target('tester@cykod.com',:name => 'Test Account')
    @site_feature = SiteFeature.create(:name => 'test_feature',:admin_user => @admin_user,:feature_type => 'dummy_feature')
  end
  

  it "shouldnt save without a target" do
    @change.should_not be_valid
    @change.target = @site_feature
    @change.should be_valid
  end
  
  
  it "should create a new change after saving site feature" do 
    EditorChange.count.should == 1
    lambda {
      @site_feature.update_attributes(:name => 'test_feature2')
      @site_feature.update_attributes(:name => 'test_feature3')
    }.should change { EditorChange.count }.by(2)
  end
  
end
