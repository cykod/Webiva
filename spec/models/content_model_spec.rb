require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../content_spec_helper"


describe ContentModel do
  include ContentSpecHelper

  reset_domain_tables :content_models,:content_model_fields,:content_model_features,:content_nodes,:content_types
  
  
  describe "Table Migration" do 
  
    before(:each) do
      DataCache.reset_local_cache
      connect_to_migrator_database
      ContentModel.connection.execute('DROP TABLE IF EXISTS cms_spec_tests')
    end

    it "should be able to create a database table and a content type" do
      cm = ContentModel.create(:name => 'spec_test')
      cm.create_table # Should create a table
    
      ContentModel.connection.execute('DROP TABLE cms_spec_tests')
    end

    it "should correctly generate valid table names" do
      cm = ContentModel.create(:name => 'This---is a test of the emergency broadcast system')
      migrator_mock = mock("ContentMigrator",:update_up => nil, :migrate_domain => nil, :suppress_messages => nil)
      ContentMigrator.should_receive(:clone).at_least(:once).and_return(migrator_mock)
      cm.create_table # Should create a table

      cm.table_name.should == 'cms_this_is_a_test_of_the_emes'
      
      cm.name = 'My Model - List of things'
      cm.create_table
      cm.table_name.should == 'cms_my_model_list_of_things'

      cm.name = 'ALLUPPERCASE!!!'
      cm.create_table
      cm.table_name.should == 'cms_alluppercases'

      cm = ContentModel.create(:name => 'ALLUPPERCASE')

      cm.create_table
      cm.table_name.should == 'cms_alluppercase_2s'

      

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
     DataCache.reset_local_cache
     connect_to_migrator_database
     ContentModel.connection.execute('DROP TABLE IF EXISTS cms_spec_tests')
    end
    
    it "should create a content type and content nodes after save" do
      ContentType.count.should == 0
      @cm = create_spec_test_content_model
      ContentType.count.should == 1
      
      ContentNode.count.should == 0
      @cm.content_model.create
      ContentNode.count.should == 1
    end

    it "should destroy content nodes after updating content node" do
      ContentType.count.should == 0
      @cm = create_spec_test_content_model
      ContentType.count.should == 1

      ContentNode.count.should == 0
      @cm.content_model.create
      ContentNode.count.should == 1

      @cm = ContentModel.find(:last)
      @cm.create_nodes = false
      @cm.save

      ContentNode.count.should == 0
    end
    
    it "should destroy content nodes after setting create_nodes to false" do
      ContentType.count.should == 0
      @cm = create_spec_test_content_model
      ContentType.count.should == 1

      ContentNode.count.should == 0
      @cm.content_model.create
      ContentNode.count.should == 1

      @cm = ContentModel.find(:last)
      @cm.create_nodes = false
      @cm.save

      ContentNode.count.should == 0
    end

    it "should try to recreate content_nodes after setting create_nodes to true" do
      ContentType.count.should == 0
      @cm = create_spec_test_content_model(:create_nodes => false)
      ContentType.count.should == 1

      ContentNode.count.should == 0
      @cm.content_model.create 
      @cm.content_model.create
      @cm.content_model.create
      ContentNode.count.should == 0

      @cm = ContentModel.find(:last)
      @cm.should_receive(:run_worker).with(:recreate_all_content_nodes)
      @cm.create_nodes = true
      @cm.save

      @cm = ContentModel.find(:last)
      @cm.recreate_all_content_nodes
      ContentNode.count.should == 3
    end
      
  end
  
end
