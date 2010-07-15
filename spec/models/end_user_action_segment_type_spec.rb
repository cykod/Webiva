require File.dirname(__FILE__) + "/../spec_helper"

describe EndUserActionSegmentType do

  reset_domain_tables :end_user_actions

  before(:each) do
    EndUserAction.create :end_user_id => 1, :renderer => 'editor/auth', :action => 'login'
    EndUserAction.create :end_user_id => 2, :renderer => 'editor/auth', :action => 'login'
    EndUserAction.create :end_user_id => 3, :renderer => 'editor/auth', :action => 'login'
    EndUserAction.create :end_user_id => 4, :renderer => 'editor/auth', :action => 'login'
    EndUserAction.create :end_user_id => 5, :renderer => 'editor/auth', :action => 'login'
    EndUserAction.create :end_user_id => 5, :renderer => 'editor/auth', :action => 'logout'
    EndUserAction.create :end_user_id => 3, :renderer => 'editor/auth', :action => 'logout'
    EndUserAction.create :end_user_id => 1, :renderer => 'editor/auth', :action => 'logout'
  end

  describe "UserActionType" do
    it "should be able to find users" do
      @type = EndUserActionSegmentType::UserActionType
      @type.select_options
      @type.is(EndUserAction, :end_user_id, [:renderer, :action], '/editor/auth/login').count.should == 5
    end
  end

  describe "ActionType" do
    it "should be able to find users" do
      @type = EndUserActionSegmentType::ActionType
      @type.select_options.length.should == 2
      @type.is(EndUserAction, :end_user_id, :action, 'login').count.should == 5
    end
  end

  describe "RendererType" do
    it "should be able to find users" do
      @type = EndUserActionSegmentType::RendererType
      @type.select_options.length.should == 1
      @type.is(EndUserAction, :end_user_id, :renderer, 'editor/auth').count.should == 8
    end
  end
end
