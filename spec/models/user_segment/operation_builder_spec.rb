require File.dirname(__FILE__) + "/../../spec_helper"

describe UserSegment::OperationBuilder do

  reset_domain_tables :user_segments

  def build(opts=nil)
    @builder = UserSegment::OperationBuilder.new nil
    @builder.build(opts) if opts
    @builder
  end

  def segment
    @segment = UserSegment.create :name => 'Test', :segment_type => 'filtered', :segment_options_text => @builder.to_expr
  end

  it "should be valid or invalid" do
    build.valid?.should be_false
    build(:field => 'email', :operation => 'is', :argument0 => 'test@test.dev').valid?.should be_true
    segment.valid?.should be_true

    build(:field => 'email', :argument0 => 'test@test.dev').valid?.should be_true

    build(:field => 'num_tags', :operation => 'count', :argument0 => '>', :argument1 => 1).valid?.should be_true
    build(:field => 'num_tags', :operation => 'count', :argument0 => '>', :argument1 => 1, :condition => 'and').valid?.should be_false
    build(:field => 'num_tags', :operation => 'count', :argument0 => '>', :argument1 => 1, :condition => 'and', :child => {:field => 'num_tags', :operation => 'count', :argument0 => '<', :argument1 => 3}).valid?.should be_false
    build(:field => 'num_tags', :operation => 'count', :argument0 => '>', :argument1 => 1, :condition => 'with', :child => {:field => 'num_tags', :operation => 'count', :argument0 => '<', :argument1 => 3}).valid?.should be_true
    build(:field => 'num_tags', :operation => 'count', :argument0 => '>', :argument1 => 1, :condition => 'with', :child => {:field => 'num_tags', :argument0 => '<', :argument1 => 3}).valid?.should be_true

    # if the field is invalid the builder is invalid
    build(:field => 'invalid_email_field', :operation => 'is', :argument0 => 'test@test.dev').valid?.should be_false

    # if the operation is invalid for the field it will set it to the first operation
    build(:field => 'email', :operation => 'invalid_operation', :argument0 => 'test@test.dev').valid?.should be_true
    @builder.operation.should_not == 'invalid_operation'
    segment.valid?.should be_true

    # if the operation is missing an argument then the builder is invalid
    build(:field => 'email', :operation => 'is', :argument0 => nil).valid?.should be_false

    # setting the condition without the child invalidates the builder
    build(:field => 'email', :operation => 'is', :argument0 => 'test@test.dev', :condition => 'and').valid?.should be_false

    build(:field => 'email', :operation => 'is', :argument0 => 'test@test.dev', :condition => 'and', :child => {:field => 'created', :operation => 'since', :argument0 => '2', :argument1 => 'days'}).valid?.should be_true
    segment.valid?.should be_true
  end

  it "should not allow invalid and conditions" do
    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login').valid?.should be_true
    segment.valid?.should be_true
    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'and', :child => {:field => 'email', :operation => 'is', :argument0 => 'test@test.dev'}).valid?.should be_false
    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'and', :child => {:field => 'occurred', :operation => 'before', :argument0 => '2', :argument1 => 'days'}).valid?.should be_true
    segment.valid?.should be_true

    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'blah', :child => {:field => 'occurred', :operation => 'before', :argument0 => '2', :argument1 => 'days'}).valid?.should be_false
  end

  it "should or conditions" do
    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login').valid?.should be_true
    segment.valid?.should be_true
    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'or', :child => {:field => 'email', :operation => 'is', :argument0 => 'test@test.dev'}).valid?.should be_true
    segment.valid?.should be_true
    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'or', :child => {:field => 'occurred', :operation => 'before', :argument0 => '2', :argument1 => 'days'}).valid?.should be_true
    segment.valid?.should be_true
  end

  it "should with conditions" do
    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login').valid?.should be_true
    segment.valid?.should be_true
    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'with', :child => {:field => 'email', :operation => 'is', :argument0 => 'test@test.dev'}).valid?.should be_true
    segment.valid?.should be_true
    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'with', :child => {:field => 'occurred', :operation => 'before', :argument0 => '2', :argument1 => 'days'}).valid?.should be_true
    segment.valid?.should be_true
  end

  it "should write output valid expression text" do
    build(:field => 'email', :operation => 'is', :argument0 => 'test@test.dev').valid?.should be_true
    @builder.to_expr.should == 'email.is("test@test.dev")'
    segment.valid?.should be_true

    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'and', :child => {:field => 'occurred', :operation => 'before', :argument0 => '2', :argument1 => 'days'}).valid?.should be_true
    @builder.to_expr.should == 'user_action.is("/editor/auth/login").occurred.before(2, "days")'
    segment.valid?.should be_true

    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'or', :child => {:field => 'email', :operation => 'is', :argument0 => 'test@test.dev'}).valid?.should be_true
    @builder.to_expr.should == 'user_action.is("/editor/auth/login") + email.is("test@test.dev")'
    segment.valid?.should be_true

    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'with', :child => {:field => 'email', :operation => 'is', :argument0 => 'test@test.dev'}).valid?.should be_true
    @builder.to_expr.should == "user_action.is(\"/editor/auth/login\")\nemail.is(\"test@test.dev\")"
    segment.valid?.should be_true

    build(:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'with', :child => {:field => 'email', :operation => 'is', :argument0 => 'test@test.dev', :condition => 'with', :child => {:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'and', :child => {:field => 'occurred', :operation => 'before', :argument0 => '2', :argument1 => 'days', :condition => 'or', :child => {:field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'or', :child => {:field => 'email', :operation => 'is', :argument0 => 'test@test.dev'}}}}}).valid?.should be_true
    @builder.to_expr.should == "user_action.is(\"/editor/auth/login\")\nemail.is(\"test@test.dev\")\nuser_action.is(\"/editor/auth/login\").occurred.before(2, \"days\") + user_action.is(\"/editor/auth/login\") + email.is(\"test@test.dev\")"
    segment.valid?.should be_true
  end

  it "should have valid prebuilt filters" do
    UserSegment::OperationBuilder.prebuilt_filters.each do |name, options|
      raise "#{name} #{options.inspect}" unless build(options).valid?
      build(options).valid?.should be_true
      segment.valid?.should be_true
    end
  end

  it "should handle Time arguments" do
    build(:field => 'created', :operation => 'between', :argument0 => '1/2/2010', :argument1 => '2/2/2010').valid?.should be_true
    @builder.argument0.should == '01/02/2010 12:00 AM'
    @builder.argument1.should == '02/02/2010 12:00 AM'
    @builder.to_expr.should == 'created.between("01/02/2010 12:00 AM", "02/02/2010 12:00 AM")'
    segment.valid?.should be_true
  end

  it "should handle the not operator" do
    build(:operator => 'not', :field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'with', :child => {:field => 'email', :operation => 'is', :argument0 => 'test@test.dev'}).valid?.should be_true
    @builder.to_expr.should == "not user_action.is(\"/editor/auth/login\")\nemail.is(\"test@test.dev\")"
    segment.valid?.should be_true

    build(:operator => '', :field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'with', :child => {:operator => 'not', :field => 'email', :operation => 'is', :argument0 => 'test@test.dev'}).valid?.should be_true
    @builder.to_expr.should == "user_action.is(\"/editor/auth/login\")\nnot email.is(\"test@test.dev\")"
    segment.valid?.should be_true

    build(:operator => 'not', :field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'with', :child => {:operator => 'not', :field => 'email', :operation => 'is', :argument0 => 'test@test.dev'}).valid?.should be_true
    @builder.to_expr.should == "not user_action.is(\"/editor/auth/login\")\nnot email.is(\"test@test.dev\")"
    segment.valid?.should be_true

    build(:operator => 'not', :field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'or', :child => {:field => 'email', :operation => 'is', :argument0 => 'test@test.dev'}).valid?.should be_true
    @builder.to_expr.should == "not user_action.is(\"/editor/auth/login\") + email.is(\"test@test.dev\")"
    segment.valid?.should be_true
  end

  it "should be able to create a builder from a user segment" do
    user_segment = UserSegment.create :name => 'Test', :segment_type => 'filtered', :segment_options_text => "user_action.is(  \"/editor/auth/login\"  )\nemail.is(\"test@test.dev\")  \n  user_action.is(\"/editor/auth/login\").occurred.before( 2,   'days' ).created.since(3,'months')  +   user_action.is(\"/editor/auth/login\") +  email.is(\"test@test.dev\"  )\nnot created.before( 3, 'years')"
    user_segment.valid?.should be_true
    build(user_segment.to_builder).valid?.should be_true

    @builder.to_expr.should == "user_action.is(\"/editor/auth/login\")\nemail.is(\"test@test.dev\")\nuser_action.is(\"/editor/auth/login\").occurred.before(2, \"days\").created.since(3, \"months\") + user_action.is(\"/editor/auth/login\") + email.is(\"test@test.dev\")\nnot created.before(3, \"years\")"

    @builder.to_expr.should == user_segment.to_expr

    @builder.condition.should == 'with'
    @builder.child_field.field.should == 'email'

    @builder.child_field.condition.should == 'with'
    @builder.child_field.child_field.field.should == 'user_action'

    @builder.child_field.child_field.condition.should == 'and'
    @builder.child_field.child_field.child_field.field.should == 'occurred'

    @builder.child_field.child_field.child_field.condition.should == 'and'
    @builder.child_field.child_field.child_field.child_field.field.should == 'created'

    @builder.child_field.child_field.child_field.child_field.condition.should == 'or'
    @builder.child_field.child_field.child_field.child_field.child_field.field.should == 'user_action'

    @builder.child_field.child_field.child_field.child_field.child_field.condition.should == 'or'
    @builder.child_field.child_field.child_field.child_field.child_field.child_field.field.should == 'email'

    @builder.child_field.child_field.child_field.child_field.child_field.child_field.condition.should == 'with'
    @builder.child_field.child_field.child_field.child_field.child_field.child_field.child_field.field.should == 'created'
    @builder.child_field.child_field.child_field.child_field.child_field.child_field.child_field.operator.should == 'not'
  end
end
