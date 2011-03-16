require  File.expand_path(File.dirname(__FILE__)) + '/../simple_content_spec_helper'

describe ContentHashModelField do

  it "should not be valid with type, module and name" do
    @field = ContentHashModelField.new nil, nil
    @field.valid?.should be_false
    @field.errors.should have(3).errors_on(:name, :field_type, :field_module)
  end

  it "should be able to use string field" do
    @field = ContentHashModelField.new nil, :name => 'Test', :field_type => 'string', :field_options => {:required => 'true'}
    @field.valid?.should be_true
    @field.module_class.class.should == Content::CoreField::StringField
    @field.representation.should == :string
    @field.required?.should be_true

    @field = ContentHashModelField.new nil, :name => 'Test', :field_type => 'string', :field => 'test'
    @field.valid?.should be_true
    @field.required?.should be_false
    @field.field.should == 'test'
    @field.id.should == :test
  end
end
