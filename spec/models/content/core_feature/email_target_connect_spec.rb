require File.dirname(__FILE__) + "/../../../spec_helper"
require File.dirname(__FILE__) + "/../../../content_spec_helper"

describe Content::CoreFeature::EmailTargetConnect do

  include ContentSpecHelper

  reset_domain_tables :content_models,:content_model_fields,:content_publications, :content_model_features,:end_users,:end_user_addresses
  
  before(:each) do
    # Create a content model an run a table migration
    # Create the table
    DataCache.reset_local_cache    
    connect_to_migrator_database
    @cm = create_spec_test_content_model
    create_dummy_fields(@cm,[ :email, :string ] )
    
  end
  
  
  after(:each) do
    # Drop the table
  end

  it "should be able to add the email_target_connect feature onto the model and verify the end user gets created " do 
  
    @cm.content_model_features.create(:feature_handler => '/content/core_feature/email_target_connect',:position => 0,
                                      :feature_options =>
                                          Content::CoreFeature::EmailTargetConnect::EmailTargetConnectOptions.new(
                                            :add_target_tags => 'Test Tag',
                                            :matched_fields => { @cm.content_model_fields[0].id => 'end_user.email',
                                                                 @cm.content_model_fields[1].id => 'end_user.first_name' }
                                          ).to_h)
    
    @cm.reload
    
    EndUser.count.should == 0
    @entry = @cm.content_model.create(:email_field => 'svend@cykod.com', :string_field => 'FirstNamer')
    @entry.email_field.should == 'svend@cykod.com'
    @entry.string_field.should == 'FirstNamer'
    EndUser.count.should == 1
    
    @usr = EndUser.find(:first)
    @usr.email.should == 'svend@cykod.com'
    @usr.first_name.should == 'FirstNamer'
    
  end

  
end
