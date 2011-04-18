require File.dirname(__FILE__) + "/../../spec_helper"
require File.dirname(__FILE__) + "/../../content_spec_helper"


describe Editor::PublicationRenderer, :type => :controller do
  include ContentSpecHelper
  
  controller_name :page
  
  integrate_views
  
  reset_domain_tables :content_publications, :content_publication_fields
  
  ContentSpecHelper.setup_content_model_test_with_all_fields self

  describe "create publication" do
 
  def generate_create_renderer(publication,data = {})
    build_renderer('/page','/editor/publication/create',data,{},:content_publication_id => publication.id)
  end
  
  before(:each) do 
   @publication = @cm.content_publications.create(:name => 'Test Form',:publication_type => 'create',:publication_module => 'content/core_publication')
   @publication.add_all_fields!

   @view_page_node = SiteVersion.default.root_node.add_subpage('created_entry')

  end
   
  it "should be able to display the default create publication form" do
     @rnd = generate_create_renderer(@publication, { :redirect_page => @view_page_node.id })
     renderer_get @rnd
  end
  
  it "should be able create a new entry" do
     @rnd = generate_create_renderer(@publication, { :redirect_page_id => @view_page_node.id })
     @cm.content_model.delete_all

     @cm.content_model.count.should == 0
     
     renderer_post @rnd, { "entry_#{@publication.id}" => { :string_field => 'Yay!' } }

     @cm.content_model.count.should == 1
     @entry = @cm.content_model.find(:first)
     @entry.string_field.should == 'Yay!'
     
     @rnd.should redirect_paragraph("/created_entry")
  end 

  it "should be able create a new entry and display success text" do
     @rnd = generate_create_renderer(@publication, { :success_text => "Request Submitted" })
     @cm.content_model.delete_all

     @cm.content_model.count.should == 0
     
     @rnd.should_render_feature('form')
     renderer_post @rnd, { "entry_#{@publication.id}" => { :string_field => 'Yay!' } }

     @cm.content_model.count.should == 1
     @entry = @cm.content_model.find(:first)
     @entry.string_field.should == 'Yay!'
     
  end 
  
  it "should be able to display default create publication form feature" do
     @feature = SiteFeature.create_default_feature(@publication.feature_name)
     
     @rnd = build_renderer('/page','/editor/publication/create',{ :redirect_page => @view_page_node.id },{},
            :content_publication_id => @publication.id,:site_feature_id => @feature.id)
     renderer_get @rnd
  end
 end


 describe "edit publication" do
 
    def generate_edit_renderer(publication,data = {},page_connection={},options={})
      build_renderer('/page','/editor/publication/edit',data,page_connection,{:content_publication_id => publication.id}.merge(options))
    end
    
    before(:each) do 
     @publication = @cm.content_publications.create(:name => 'Test Form',:publication_type => 'edit',:publication_module => 'content/core_publication')
     @publication.add_all_fields!
     @view_page_node = SiteVersion.default.root.add_subpage('created_entry')

    end 
    
    it "should be able to display the edit form on an existing entry" do
       @entry = @cm.content_model.create(:string_field => 'This is a test of the emergency broadcast system')

       @rnd = generate_edit_renderer(@publication, { :return_page_id => @view_page_node.id }, { :input => [ :entry_id, @entry.id ] })
       @rnd.should_render_feature('form')
       renderer_get @rnd
    end
    
     it "should be able to display default edit publication form feature" do
         @feature = SiteFeature.create_default_feature(@publication.feature_name)
         
         @entry = @cm.content_model.create(:string_field => 'This is a test of the emergency broadcast system')

         @rnd = generate_edit_renderer(@publication, { :return_page_id => @view_page_node.id }, { :input => [ :entry_id, @entry.id ] }, :site_feature_id => @feature.id)
         @rnd.should_render_feature('form')
         renderer_get @rnd
         
      end    
    
    it "should be able to edit and existing entry" do
       @entry = @cm.content_model.create(:string_field => 'This is a test of the emergency broadcast system')
       
       @entry.string_field.should == "This is a test of the emergency broadcast system"

       @cm.content_model.count.should == 1
       @rnd = generate_edit_renderer(@publication, { :return_page_id => @view_page_node.id }, { :input => [ :entry_id, @entry.id ] })
       
       renderer_post @rnd, { "entry_#{@publication.id}" => { :string_field => 'Yay!' } }

       @cm.content_model.count.should == 1
       @entry.reload
       @entry.string_field.should == 'Yay!'
     
       @rnd.should redirect_paragraph("/created_entry")       
    end
    
    
    
    it "should be render nothing if not allowed to create a new entry" do 
       @entry = @cm.content_model.create(:string_field => 'This is a test of the emergency broadcast system')
       @rnd = generate_edit_renderer(@publication, { :redirect_page => @view_page_node.id })
       
       renderer_get @rnd
       
       @rnd.should render_paragraph(:text => '')
    end
    
    it "should be display the create form if allowed" do
       @rnd = generate_edit_renderer(@publication, { :return_page_id => @view_page_node.id,:allow_entry_creation => true })
    
       @rnd.should_render_feature('form')
       renderer_get @rnd
    end 
    
    it "should be able to create a new entry if allowed" do
       @rnd = generate_edit_renderer(@publication, { :return_page_id => @view_page_node.id,:allow_entry_creation => true })
       
       @cm.content_model.count.should == 0

       renderer_post @rnd, { "entry_#{@publication.id}" => { :string_field => 'This is another test of the emergency broadcast system' } }

       @cm.content_model.count.should == 1
       @entry = @cm.content_model.find(:first)
       @entry.string_field.should == 'This is another test of the emergency broadcast system'
     
       @rnd.should redirect_paragraph("/created_entry")       
    end
    
 end
  
  
 describe "list publication" do
    
    def generate_list_renderer(publication,data = {},page_connection={})
      build_renderer('/page','/editor/publication/list',data,page_connection,:content_publication_id => publication.id)
    end
    
    before(:each) do 
     @publication = @cm.content_publications.create(:name => 'Test List',:publication_type => 'list',:publication_module => 'content/core_publication')
      @publication.add_all_fields!

     @view_page_node = SiteVersion.default.root.add_subpage('detail_page')
    end     
    
    it "should be able to display the list publication" do
       @entry = @cm.content_model.create(:string_field => 'This is a test of the emergency broadcast system')
       @entry = @cm.content_model.create(:string_field => 'This is a second test of the emergency broadcast system')
    
       @rnd = generate_list_renderer(@publication, { :detail_page => @view_page_node.id })
    
       @rnd.should_render_feature('list')
       renderer_get @rnd
    end

 end
 
 describe "admin list publication" do
   
    def generate_admin_list_renderer(publication,data = {},page_connection={})
      build_renderer('/page','/editor/publication/list',data,page_connection,:content_publication_id => publication.id)
    end
    
    before(:each) do 
     @publication = @cm.content_publications.create(:name => 'Test List',:publication_type => 'admin_list',:publication_module => 'content/core_publication')
     @publication.add_all_fields!
      @view_page_node = SiteVersion.default.root.add_subpage('detail_page')


      
    end     
    
    it "should be able to display the admin list publication" do
       @entry = @cm.content_model.create(:string_field => 'This is a test of the emergency broadcast system')
       @entry = @cm.content_model.create(:string_field => 'This is a second test of the emergency broadcast system')
    
       @rnd = generate_admin_list_renderer(@publication, { :detail_page => @view_page_node.id })
    
       @rnd.should_render_feature('list')
       renderer_get @rnd
    end
 
 end
 
 
 describe 'view publication' do
  
    def generate_view_renderer(publication,data = {},page_connection={})
      build_renderer('/page','/editor/publication/view',data,page_connection,:content_publication_id => publication.id)
    end
    
    before(:each) do 
     @publication = @cm.content_publications.create(:name => 'Test List',:publication_type => 'view',:publication_module => 'content/core_publication')
      @publication.add_all_fields!

     @view_page_node = SiteVersion.default.root.add_subpage('return_page')
    end     
    
    it "should be able to display view publication" do
       @entry = @cm.content_model.create(:string_field => 'This is a test of the emergency broadcast system')
    
       @rnd = generate_view_renderer(@publication, { :return_page => @view_page_node.id }, { :input => [ :entry_id, @entry.id ] })
    
       @rnd.should_render_feature('display')
       renderer_get @rnd
    end
    
    it "should render nothing if there's no entry" do 
       @rnd = generate_view_renderer(@publication, { :return_page => @view_page_node.id })
       renderer_get @rnd
       @rnd.should render_paragraph(:text => '')
    end
 
 end
  

  
end
