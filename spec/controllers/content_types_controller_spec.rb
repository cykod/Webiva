require File.dirname(__FILE__) + "/../spec_helper"

describe ContentTypesController, "handle content types" do

 integrate_views
 
 reset_domain_tables :content_types

 before(:each) do 
      @myself = EndUser.push_target('test@webiva.com')
      @myself.user_class = UserClass.client_user_class
      @myself.save
      
      controller.should_receive('myself').at_least(:once).and_return(@myself)
      
      @ct = ContentType.create(:content_name => 'Dummy Type')
  end

  it "should handle the types table" do 
  
    # Test all the permutations of an active table
    controller.should handle_active_table(:content_types_table) do |args|
      post 'display_content_types_table', args
    end
  end  
  
  it "should be able to display the index page" do
  
    get :index
  
  end
 
end

