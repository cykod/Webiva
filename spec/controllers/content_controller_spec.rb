require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../content_spec_helper"

describe ContentController, "create a content model" do

  reset_domain_tables :end_users, :roles, :user_roles, :access_tokens, :end_user_tokens

  include ContentSpecHelper

 integrate_views
 
 before(:all) do
    # Need to clean out the content models and create a new content model
    # But don't want to do this before each one
    create_content_model_with_all_fields
  end

  describe "Should be able to manipulate content" do 
    
    before(:each) do
      mock_editor
    end
    
    describe "Should be able to list, add and edit entries" do 
      
      # Kill the ContentModel table
      reset_domain_tables :end_users, :cms_controller_spec_tests
      
      it "should handle custom content models table" do 
        get :custom
      end  
      
      it "should be able to display the index page" do
        get :index
      end
      
      it "should be able to display a custom content model table" do
        @cm.content_model.create(:string_field => 'Tester',:date_field => "6/13/2009")
        @cm.content_model.create(:string_field => 'Tester2',:date_field => "6/13/2009")
        
        get :view, :path => [ @cm.id ]
      end
      
      it "should be able to display the view of an item" do
        @entry = @cm.content_model.create(:string_field => '<h1>Test Escaped Field</h1>',:date_field => "6/13/2009", :html_field => '<h1>Html Field</h1>')

        get :entry, :path => [ @cm.id, @entry.id ]

        response.should render_template('content/entry')
        # Make sure escaped field shown correctly
        
        
        response.body.should include("&lt;h1&gt;Test Escaped Field&lt;/h1&gt;")
        response.body.should include('<h1>Html Field</h1>')
      end
      

      it "should be able to display a creation form" do
        get :edit_entry, :path => [ @cm.id ]
        
        response.should render_template('content/edit_entry')  
      end
      
      it "shouldn't create an item if the required string field isn't set" do
        cls = @cm.content_model
        @entry = cls.new 
        
        # cls is unnamed so we need to chain our should_receives together
        ContentModel.should_receive(:find).at_least(:once).and_return(@cm)
        @cm.should_receive(:content_model).at_least(:once).and_return(cls)
        cls.should_receive(:new).and_return(@entry)
        
        put :edit_entry, :path => [ @cm.id], :entry => { :html_field => 'HTML FIELD!' }
        
        
        response.should render_template('content/edit_entry')
      end
      
      it "should create an item if the required string field is set" do
        cls = @cm.content_model
        @entry = cls.new 
        
        # cls is unnamed so we need to chain our should_receives together
        ContentModel.should_receive(:find).at_least(:once).and_return(@cm)
        @cm.should_receive(:content_model).at_least(:once).and_return(cls)
        cls.should_receive(:new).and_return(@entry)
        
        put :edit_entry, :path => [ @cm.id], :entry => { :string_field => 'Testerama', :html_field => 'HTML FIELD!' }
        
        response.should render_template('content/edit_entry')
      end  

      it "should be view the edit form of an existing item " do
        @entry = @cm.content_model.create(:string_field => '<h1>Test Escaped Field</h1>',:date_field => "6/13/2009", :html_field => '<h1>Html Field</h1>')

        get :edit_entry, :path => [ @cm.id, @entry.id ]
        
        response.should render_template('content/edit_entry')  
      end


      it "should be able modify an existing item " do
        @entry = @cm.content_model.create(:string_field => '<h1>Test Escaped Field</h1>',:date_field => "6/13/2009", :html_field => '<h1>Html Field</h1>')

        post :edit_entry, :path => [ @cm.id, @entry.id ], :entry => { :string_field => 'Test Field' }
        
        response.should redirect_to(:action => 'view', :path => [ @cm.id ] )  
      end
    end
    
    describe "should be able to edit fields" do
      
      it "should be able to show the edit fields page" do 
        get :edit, :path => [ @cm.id ]
        
        response.should render_template('content/edit')
      end
      
    end

  end

  describe "Should be able to control access" do

    it "should kick user out if they have no permissions" do
      mock_editor('test@webiva.com',[]) # no permissions

      get :view, :path => [ @cm.id ]

      response.should redirect_to(:controller => '/manage/access', :action => 'denied')
    end


    it "should let the user in if they are allowed" do
      mock_editor('test@webiva.com',[ :editor_content ])
      # content permission

      get :view, :path => [ @cm.id ]

      response.should render_template('content/view')
    end


    it "shouldn't let users in if the content model is protected" do
      @cm.update_attributes(:view_access_control => true)

      mock_editor('test@webiva.com',[ :editor_content ])
      # content permission

      get :view, :path => [ @cm.id ]

      response.should redirect_to(:controller => '/manage/access', :action => 'denied')
    end


     it "should let users in if the content model is protected and we have an access token" do
      @cm.update_attributes(:view_access_control => true)
      tkn = AccessToken.create(:editor => true,:token_name => 'Tester')

      tkn.has_role('view_access_control',@cm)

      mock_editor('test@webiva.com',[ :editor_content ])
      # content permission

      @myself.add_token!(tkn)
      
      get :view, :path => [ @cm.id ]

      response.should render_template('content/view')
    end

  end
 
end

