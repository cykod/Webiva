require File.dirname(__FILE__) + "/../spec_helper"

describe TemplatesController do
  integrate_views

  reset_domain_tables :site_template, :domain_file, :site_template_zone, :site_feature, :site_node, :page_paragraph, :page_revision

  before(:each) do
    mock_editor

    @template1 = SiteTemplate.create :name => 'Template 1'
    @template2 = SiteTemplate.create :name => 'Template 2', :template_html => '<cms:zone name="Main"/><cms:zone name="Sidebar"/>'
    @template2.update_zones_and_options
    @template2.reload
  end

  it "should be able to display the index page" do
    get :index
  end

  it "should handle theme list" do
    # Test all the permutations of an active table
    controller.should handle_active_table(:site_templates_table) do |args|
      post 'display_site_templates_table', args
    end
  end

  it "should be able to delete templates" do
    assert_difference 'SiteTemplate.count', -2 do
      post 'display_site_templates_table', :table_action => 'delete', :template => {@template1.id => @template1.id, @template2.id => @template2.id}
    end
  end

  it "should be able to export templates" do
    post 'create_bundle', :template => {@template1.id => @template1.id, @template2.id => @template2.id}, :bundler => {:name => 'Bundle Test'}, :commit => 1
    bundle = DomainFile.last :conditions => {:parent_id => DomainFile.themes_folder, :file_type => 'doc'}
    bundle.should_not be_nil
    bundle.name.should == 'bundle_test.webiva'
    bundle.file_size.should > 0
  end

  it "should be able to render create_bundle" do
    get 'create_bundle', :template => {@template1.id => @template1.id, @template2.id => @template2.id}
    response.body.should include("template[#{@template1.id}]")
  end

  it "should be able to render import_bundle" do
    get 'import_bundle'
  end

  it "should be able to render import_bundle" do
    bundler = WebivaBundler.new :name => 'Test Bundle'
    bundler.export_object @template1
    bundle = bundler.export
    DomainModel.should_receive(:run_worker)
    post 'import_bundle', :bundler => {:bundle_file_id => bundle.id}, :commit => 1
  end

  it "should be able to render import_bundle" do
    bundler = WebivaBundler.new :name => 'Test Bundle'
    bundler.export_object @template1
    bundle = bundler.export
    post 'import_bundle', :bundler => {:bundle_file_id => bundle.id}, :select => 1
    response.body.should include('Test Bundle')
  end

  it "should be able to render import_bundle" do
    bundler = WebivaBundler.new :name => 'Test Bundle'
    bundler.export_object @template1
    bundle = bundler.export
    post 'import_bundle', :bundler => {:bundle_file_id => bundle.id}
    response.should redirect_to(:action => 'index')
  end

  it "should be able to check to see if a bundle finished importing" do
    Workling.return.should_receive(:get).with('test').and_return({})
    get 'import_bundle', :key => 'test'
    response.headers['Refresh'].should_not be_nil
  end

  it "should be able to check to see if a bundle finished importing" do
    Workling.return.should_receive(:get).with('test').and_return({:processed => true})
    get 'import_bundle', :key => 'test'
    response.headers['Refresh'].should be_nil
    response.should redirect_to(:action => 'index')
  end

  it "should be able to render apply a theme" do
    get 'apply_theme', :path => [@template1.id]
  end

  it "should be able to render apply a theme" do
    SiteTemplate.should_receive(:find).with(@template1.id).and_return(@template1)
    @template1.should_receive(:apply_to_site).exactly(0)
    DomainModel.should_receive(:expire_site).exactly(0)
    post 'apply_theme', :path => [@template1.id]
    response.should redirect_to(:action => 'index')
  end

  it "should be able to render apply a theme" do
    DomainModel.should_receive(:expire_site).once
    post 'apply_theme', :path => [@template1.id], :commit => 1
    response.should redirect_to(:action => 'index')
  end

  it "should be able to render new theme" do
    get 'new'
  end

  it "should not create a template unless committing" do
    assert_difference 'SiteTemplate.count', 0 do
      post 'new', :site_template => {:name => 'Template 3'}
    end
    response.should redirect_to(:action => 'index')
  end

  it "should be able to create a new template" do
    assert_difference 'SiteTemplate.count', 1 do
      post 'new', :site_template => {:name => 'Template 3'}, :commit => 1, :path => []
    end
    new_template = SiteTemplate.last
    new_template.name.should == 'Template 3'
    new_template.parent_id.should be_nil
    response.should redirect_to(:action => 'edit', :path => new_template.id)
  end

  it "should be able to create a new child template" do
    assert_difference 'SiteTemplate.count', 1 do
      post 'new', :site_template => {:name => 'Template 3'}, :commit => 1, :path => [@template2.id]
    end
    new_template = SiteTemplate.last
    new_template.name.should == 'Template 3'
    new_template.parent_id.should == @template2.id
    response.should redirect_to(:action => 'edit', :path => new_template.id)
  end

  it "should be able to render edit a template" do
    get 'edit', :path => [@template2.id]
    response.body.should include(@template2.name)
    response.body.should include('Structural Styles')
    response.body.should include('Design Styles')
  end

  it "should be able to render different versions" do
    get 'edit', :path => [@template2.id], :version => 1
    response.should redirect_to(:action => 'edit', :path => [@template2.id])
  end

  it "should be able to load different versions" do
    flash[:template_version_load] = 1
    SiteTemplate.should_receive(:find).with(@template2.id).and_return(@template2)
    @template2.should_receive(:load_version).with(1)
    get 'edit', :path => [@template2.id]
  end

  it "should be able to change view" do
    get 'edit', :path => [@template2.id], :view => 'change'
  end

  it "should be able to view child template" do
    @child = SiteTemplate.create :name => 'Child Template', :parent_id => @template1.id
    @child.id.should_not be_nil
    get 'edit', :path => [@child.id]
    response.body.should_not include('Structural Styles')
    response.body.should_not include('Design Styles')
  end

  it "should be able to get default feature" do
    get 'default_feature_data', :feature_type => 'login'
    response.body.should include('Login')
  end

  it "should be able to refresh_styles, style_design" do
    get 'refresh_styles', :path => [@template1.id], :type => 'style_design'
  end

  it "should be able to refresh_styles, structural_design" do
    get 'refresh_styles', :path => [@template1.id], :type => 'structural_design'
  end

  it "should be able to update a template" do
    zone1 = @template2.site_template_zones[0].id
    zone2 = @template2.site_template_zones[1].id
    zone_order = "#{zone2},#{zone1}"
    post 'update', :path => [@template2.id], :zone_order => zone_order, :site_template => {:domain_file_id => DomainFile.root_folder.id, :name => 'Basic Template 1', :style_design => '* { padding: 0; margin: 0; }', :style_struct => '#black { color: #000; }', :template_html => '<cms:zone name="Main"/><cms:zone name="Sidebar"/><cms:zone name="Footer"/>'}

    @template2.reload
    @template2.name.should == 'Basic Template 1'
    @template2.site_template_zones.count.should == 3
    @template2.site_template_zones[0].id.should == zone2
    @template2.site_template_zones[1].id.should == zone1
    @template2.style_struct.should == '#black { color: #000; }'
    @template2.style_design.should == '* { padding: 0; margin: 0; }'
    @template2.template_html.should == '<cms:zone name="Main"/><cms:zone name="Sidebar"/><cms:zone name="Footer"/>'
    @template2.domain_file_id.should == DomainFile.root_folder.id
  end

  it "should be able to remove a zone from a template" do
    zone1 = @template2.site_template_zones[0].id
    zone2 = @template2.site_template_zones[1].id
    zone_order = "#{zone2},#{zone1}"
    post 'update', :path => [@template2.id], :zone_order => zone_order, :site_template => {:template_html => '<cms:zone name="Main"/><cms:zone name="Footer"/>'}

    @template2.reload
    @template2.site_template_zones.count.should == 2
    @template2.site_template_zones[0].id.should == zone1
  end

  it "should be able to update a child template" do
    @child = SiteTemplate.create :name => 'Child Template', :parent_id => @template2.id
    post 'update', :path => [@child.id], :site_template => {:template_html => '<cms:zone name="Child"/>'}

    @child.reload
    @child.site_template_zones.count.should == 1
    @child.template_html.should == '<cms:zone name="Child"/>'
  end

  it "should be able to load_translation" do
    post 'load_translation', :show_languages => 'en', :template_id => @template1.id
  end

  it "should be able to preview the template" do
    get 'preview', :path => [@template2.id, 'en']
  end

  it "should be able to preview the template" do
    get 'preview_css', :path => [@template2.id, 'en']
  end

  describe 'Features' do
    before(:each) do
      @feature1 = @template2.site_features.create :name => 'My Login', :feature_type => 'login', :body => '<cms:logged_in>Logged In</cms:logged_in>'
      @feature2 = @template2.site_features.create :name => 'My Login 2', :feature_type => 'login', :body => '<cms:logged_in>Logged In 2</cms:logged_in>'
      @feature3 = SiteFeature.create :name => 'My Login 4', :feature_type => 'login', :body => '<cms:logged_in>Logged In 4</cms:logged_in>'
    end

    it "should handle feature list" do
      # Test all the permutations of an active table
      @feature1.id.should_not be_nil
      controller.should handle_active_table(:features_table) do |args|
        post 'display_features_table', args
      end
    end

    it "should be able to set the feature theme" do
      @feature2.site_template_id.should == @template2.id
      post 'display_features_table', :table_action => 'theme', :site_template_id => @template1.id, :feature => {@feature1.id => @feature1.id, @feature2.id => @feature2.id}
      @feature2.reload
      @feature2.site_template_id.should == @template1.id
    end

    it "should render the features page" do
      get 'features'
      response.body.should include(@feature1.name)
    end

    it "should render the select_theme page" do
      get 'select_theme'
      response.body.should include(@template2.name)
    end

    it "should render the new_feature page" do
      get 'new_feature'
    end

    it "should be able to create a new feature" do
      assert_difference 'SiteFeature.count', 1 do
        post 'new_feature', :feature => {:name => 'Login 3', :feature_type => 'login'}
      end

      new_feature = SiteFeature.last
      new_feature.name.should == 'Login 3'
      new_feature.feature_type.should == 'login'

      response.should redirect_to(:action => 'feature', :path => [new_feature.id])
    end

    it "should be able to render the feature" do
      get 'feature', :path => [@feature1.id]
      response.body.should include(@feature1.name)
    end

    it "should be able to render the feature" do
      get 'feature', :path => [@feature3.id]
      response.body.should include(@feature3.name)
    end

    it "should be able to copy the feature" do
      get 'feature', :path => [@feature1.id], :copy_feature_id => 1
      response.body.should include("#{@feature1.name} (Copy)")
    end

    it "should set the version and redirect, feature" do
      get 'feature', :path => [@feature1.id], :version => 1
      response.should redirect_to(:action => 'feature', :path => [@feature1.id])
    end

    it "should set the version and redirect, feature" do
      flash[:feature_version_load] = 1
      get 'feature', :path => [@feature1.id]
    end

    it "should be able to render the feature_styles" do
      get 'feature_styles', :path => [@feature1.id]
    end

    it "should be able to render the feature_styles" do
      get 'feature_styles', :path => [@feature3.id]
    end

    it "should be able to render the feature_styles" do
      get 'feature_styles', :path => [], :feature => {:feature_type => 'login'}
    end

    it "should be able to edit a feature" do
      post 'save_feature', :para_index => 1, :path => [@feature1.id], :feature => {:body => 'New Body'}

      @feature1.reload
      @feature1.body.should == 'New Body'
    end

    it "should not be able to edit a feature if body is incorrect" do
      post 'save_feature', :para_index => 1, :path => [@feature1.id], :feature => {:body => '<cms:logged>Failure</cms:logged_in>'}

      @feature1.reload
      @feature1.body.should_not == '<cms:logged>Failure</cms:logged_in>'
    end

    it "should be able to edit a feature if body is incorrect" do
      post 'save_feature', :para_index => 1, :path => [@feature1.id], :feature => {:body => '<cms:logged>Failure</cms:logged_in>'}, :ignore_xml_errors => true

      @feature1.reload
      @feature1.body.should == '<cms:logged>Failure</cms:logged_in>'
    end

    it "should be able to edit a feature" do
      assert_difference 'SiteFeature.count', 1 do
        post 'save_feature', :para_index => 1, :path => [], :feature => {:name => 'New Login', :feature_type => 'login', :body => 'New Body'}
      end

      new_feature = SiteFeature.last
      new_feature.name.should == 'New Login'
      new_feature.body.should == 'New Body'
    end

    describe 'Paragraphs' do
      before(:each) do
        SiteVersion.current.root_node.push_subpage('login') do |nd, rv|
          @paragraph1 = rv.push_paragraph '/editor/auth', 'login'
        end
      end

      it "should be able to render popup feature for a paragraph" do
        get 'popup_feature', :paragraph_id => @paragraph1.id, :para_index => 1, :path => []
      end

      it "should redirect to the popup feature for a paragraph with a version" do
        get 'popup_feature', :paragraph_id => @paragraph1.id, :para_index => 1, :path => [], :version => 1
        response.should redirect_to(:action => 'popup_feature', :paragraph_id => @paragraph1.id, :para_index => 1, :path => [])
      end
    end
  end
end
