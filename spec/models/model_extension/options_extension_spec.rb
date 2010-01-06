require File.dirname(__FILE__) + "/../../spec_helper"

describe ModelExtension::OptionsExtension do

  it "should be able to add options to a model" do

    class TestOptionsModel
      include ModelExtension::OptionsExtension
      
      attr_accessor :test_field
      has_options :test_field, [['Field A','a'],['Field B','b']]

    end

    obj = TestOptionsModel.new

    TestOptionsModel.test_field_options_hash.should == {  
      'a' => 'Field A',
      'b' => 'Field B'
    }
    
    TestOptionsModel.test_field_select_options.should ==  [['Field A','a'],['Field B','b']]

    obj.test_field = 'b'

    obj.test_field_display.should == 'Field B'
  
  end	 


  it "should be able add required options that validate correctly" do
    class RequiredOptionsTestModel  < HashModel
      attributes :test_field => nil

      validating_options :test_field,  [['Field A','a'],['Field B','b']]
    end

    obj = RequiredOptionsTestModel.new(nil)

    obj.test_field = 'c'
    obj.should_not be_valid

    obj.test_field = 'a'
    obj.should be_valid
    
  end

end
