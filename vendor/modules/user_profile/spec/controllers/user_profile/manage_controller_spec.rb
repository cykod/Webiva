require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/content_spec_helper"

describe UserProfile::ManageController do
  include ContentSpecHelper

  integrate_views

  reset_domain_tables :user_profile_types, :user_profile_entries, :content_types,  :content_publications, :end_users, :end_user_caches, :cms_controller_spec_tests, :user_profile_type_user_classes

  ContentSpecHelper.setup_content_model_test_with_all_fields self

  before do
    mock_editor
    test_activate_module('user_profile')
    @cm = ContentModel.find(:first)
    @prof_type =  UserProfileType.create(:name => "Test profile type default",
                                         :user_classes => [ { 'id' => UserClass.default_user_class_id.to_s } ],
                                         :content_model_id => @cm.id,
                                         :content_model_field_id => @cm.content_model_fields.core_fields('belongs_to')[0].id)
  end

  describe "viewing and editing" do

    before do
      @user = EndUser.push_target('tester@webiva.org')
      @profile_entry = UserProfileEntry.fetch_entry(@user,@prof_type.id)
    end


    it "should fetch a profile entry" do
      get "view", :path => [ @user.id], :tab => 1
      response.should render_template('user_profile/manage/_view') 
    end

    it "should update a profile" do
      @profile_entry.update_attribute :published, false
      @profile_entry.reload
      @profile_entry.published.should be_false
      assert_difference "CmsControllerSpecTest.count", 1 do 
        post "view", :path => [ @user.id ], :tab => 1, :profile_type_id => @prof_type.id, :entry => { :string_field => 'Yay!' }, :profile => {:published => true}
      end
      @profile_entry.reload
      @profile_entry.published.should be_true
      @profile_entry.content_model_entry.string_field.should == 'Yay!'
    end
    
  end

  describe "viewing and editing without content model" do

    before do
      @prof_type =  UserProfileType.create(:name => "Test profile type default",
                                           :user_classes => [ { 'id' => UserClass.default_user_class_id.to_s} ])

      @user = EndUser.push_target('tester@webiva.org')
      @profile_entry = UserProfileEntry.fetch_entry(@user,@prof_type.id)
    end


    it "should fetch a profile entry" do
      get "view", :path => [ @user.id], :tab => 1
      response.should render_template('user_profile/manage/_view') 
    end

    it "should update a profile" do
      @profile_entry.update_attribute :published, false
      @profile_entry.reload
      @profile_entry.published.should be_false
      post "view", :path => [ @user.id ], :tab => 1, :profile_type_id => @prof_type.id, :profile => {:published => true}
      @profile_entry.reload
      @profile_entry.published.should be_true
    end
    
  end

  describe 'edge cases' do
    it 'should render a layout with instructions if no profile type exists' do
      @test_user1 = EndUser.push_target('Tester@test.com', :user_class_id => UserClass.client_user_class_id)
      post("view", :path => [@test_user1.id])
      response.should render_template('user_profile/manage/_no_profile_type')
    end

  end
end
