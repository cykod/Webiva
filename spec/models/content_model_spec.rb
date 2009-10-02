require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../content_spec_helper"


describe ContentModel do
  include ContentSpecHelper

  reset_domain_tables :content_models,:content_model_fields,:content_model_features,:content_nodes,:content_types
  
  
  describe "Table Migration" do 
  
    before(:each) do
      connect_to_migrator_database
      ContentModel.connection.execute('DROP TABLE IF EXISTS cms_spec_tests')
    end

    it "should be able to create a database table and a content type" do
      cm = ContentModel.create(:name => 'spec_test')
      cm.create_table # Should create a table
    
      ContentModel.connection.execute('DROP TABLE cms_spec_tests')
    end
    
    it "should be able to add entries to the table (no fields, just id)" do
      cm = ContentModel.create(:name => 'spec_test')
      cm.create_table # Should create a table
      
      cls = cm.content_model
      
      entry = cls.create
      entry.id.should == 1
      
      cls.count.should == 1

      entry = cls.create
      cls.count.should == 2
    
      ContentModel.connection.execute('DROP TABLE cms_spec_tests')
    end
    
  end
  
  describe "Content Node Creation" do
    
      before(:each) do
       connect_to_migrator_database
      end
      
      it "should create a content type and content nodes after save" do
       ContentType.count.should == 0
       @cm = create_spec_test_content_model
       ContentType.count.should == 1
       
       ContentNode.count.should == 0
       @cm.content_model.create
       ContentNode.count.should == 1
      end
      
  end
  
end
