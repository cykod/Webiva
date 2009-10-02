require File.dirname(__FILE__) + "/../spec_helper"

describe SiteFeature do
  
  reset_domain_tables :editor_changes,  :site_feature, :site_template

  before(:each) do
    @feature = SiteFeature.new
    @valid_feature = SiteFeature.new(:name => 'Test Feature',:feature_type => 'dummy_feature')
  end


  it "should require only a name and a feature_type" do
    @feature.should_not be_valid
    @feature.name = "Test Feature"
    @feature.feature_type = 'dummy_feature'
    @feature.should be_valid
  end
  
  it "should return an error with invalid xml if we ask it to validate the xml" do
    @valid_feature.name = "Test Feature"
    @valid_feature.body = <<-EOF
<div>
  <cms:entry><b><cms:title/></cms:entry>
</div> 
EOF
    @valid_feature.should be_valid
    @valid_feature.validate_xml = true
    @valid_feature.should_not be_valid
  end
  
 it "should be valid with valid xml if we ask it to validate the xml" do
    @valid_feature.name = "Test Feature"
    @valid_feature.body = <<-EOF
<div>
  <cms:entry><b><cms:title/></b></cms:entry>
</div> 
EOF
    @valid_feature.validate_xml = true
    @valid_feature.should be_valid
  end  
end
