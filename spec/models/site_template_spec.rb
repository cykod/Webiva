require File.dirname(__FILE__) + "/../spec_helper"

describe SiteTemplate do

  reset_domain_tables :editor_changes, :site_feature, :site_template, :domain_file, :site_template_zone, :site_template_rendered_part, :site_node, :page_paragraph, :page_revision, :site_node_modifiers

  
  before(:each) do
    @site_template = SiteTemplate.new(:name => 'Test Template')
  end

  it "should update the special attribute of a folder after a save" do
    folder1 = DomainFile.create_folder("Original")
    folder2 = DomainFile.create_folder("Second")
    @site_template.domain_file = folder1
    @site_template.save
    
    folder1.reload
    folder1.special.should == 'template'
    
    @site_template.domain_file_id = folder2.id
    @site_template.save
    
    folder1.reload
    folder2.reload
    
    folder1.special.should be_blank
    folder2.special.should == 'template'
  end

  it "should be able to create the default template" do
    assert_difference 'SiteTemplate.count', 1 do
      SiteTemplate.create_default_template
    end
  end

  it "should be able to update zones and options" do
    @site_template.template_html = '<cms:zone name="Main"/><cms:zone name="Sidebar"/>'
    assert_difference 'SiteTemplate.count', 1 do
      assert_difference 'SiteTemplateZone.count', 0 do
        @site_template.save
      end
    end

    assert_difference 'SiteTemplateZone.count', 2 do
      @site_template.update_zones_and_options
    end
  end

  it "should have site and mail template options" do
    SiteTemplate.create :name => 'site template 1'
    SiteTemplate.create :name => 'site template 2'
    SiteTemplate.site_template_options.size.should == 2

    SiteTemplate.create :name => 'mail template 1', :template_type => 'mail'
    SiteTemplate.create :name => 'mail template 2', :template_type => 'mail'
    SiteTemplate.mail_template_options.size.should == 2
  end

  it "should be able to work with variables in the css" do
    @site_template.style_struct = '#space { size: 13px; }'
    @site_template.style_design = 'body { color: <cms:var name="font_color" type="color" default="#FFF"/>; }'
    @site_template.template_html = '<cms:zone name="Main"/>'
    @site_template.save
    @site_template.update_zones_and_options
    @site_template.options[:options][0][0].should == 'font_color'

    @site_template.options[:values]['font_color'] = '#F00'
    @site_template.save

    @site_template.reload

    @site_template.rendered_parts 'en'

    design_part = @site_template.site_template_rendered_parts.find_by_part_and_idx 'css', 2
    design_part.body.should == "body { color: #F00; }"
  end

  if LESS_AVAILABLE
    describe 'Less' do
      it "should support Less in the the design and structual css" do
        @site_template.style_struct = '@font_size: 13px;' + "\n" + '#space { size: @font_size; }'
        @site_template.style_design = '@font_color: <cms:var name="font_color" type="color" default="#FFF"/>;' + "\n" 'body { color: @font_color; }'
        @site_template.template_html = '<cms:zone name="Main"/>'
        @site_template.save
        @site_template.update_zones_and_options
        @site_template.options[:options][0][0].should == 'font_color'

        @site_template.options[:values]['font_color'] = '#F00'
        @site_template.save

        @site_template.reload

        @site_template.rendered_parts 'en'

        struct_part = @site_template.site_template_rendered_parts.find_by_part_and_idx 'css', 1
        struct_part.body.should == "#space { size: 13px; }\n"

        design_part = @site_template.site_template_rendered_parts.find_by_part_and_idx 'css', 2
        design_part.body.should == "body { color: #ff0000; }\n"
      end
    end
  end

  describe 'Bundler' do
    before(:each) do
      @site_template.style_struct = '#space { size: 13px; }'
      @site_template.style_design = 'body { color: <cms:var name="font_color" type="color" default="#FFF"/>; }'
      @site_template.template_html = '<cms:zone name="Main"/> <cms:zone name="Sidebar"/>'
      @site_template.domain_file_id = DomainFile.create_folder('Test Theme').id
      @site_template.save
      @site_template.update_zones_and_options

      # Images
      @df = DomainFile.create(:filename => fixture_file_upload("files/rails.png",'image/png'), :parent_id => @site_template.domain_file_id)
      @thumb = DomainFile.create(:filename => fixture_file_upload("files/rails.png",'image/png'))

      # Features
      @site_template.site_features.create :name => 'Login', :feature_type => 'login', :body => '<cms:logged_in>yes i am</cms:logged_in>'

      SiteTemplate.create :name => 'Child Theme', :parent_id => @site_template.id, :template_html => '<cms:zone name="Main"/>'

      @site_template.reload

      @bundler = WebivaBundler.new :name => 'Test Bundle', :thumb_id => @thumb.id
      @bundler.export_object @site_template
      @bundle_file = @bundler.export
    end

    after(:each) do
      @df.destroy
      @thumb.destroy
      @bundle_file.destroy
    end

    it "should be setup" do
      SiteTemplate.count.should == 2
      SiteFeature.count.should == 1
      DomainFile.count.should == 6
      SiteTemplateZone.count.should == 2

      @site_template.child_templates.count.should == 1
      @site_template.site_features.count.should == 1
      @site_template.domain_file.name.should == 'Test Theme'
    end

    it "should have a bundle file" do
      @bundle_file.id.should_not be_nil
    end

    it "should be able to import the bundle" do
      assert_difference 'SiteTemplate.count', 2 do
        assert_difference 'SiteFeature.count', 1 do
          assert_difference 'DomainFile.count', 4 do
            import_bundler = WebivaBundler.new(:bundle_file_id => @bundle_file.id, :importing => true, :replace_same => false)
            import_bundler.valid?.should be_true
            import_bundler.import
          end
        end
      end

      @new_template = SiteTemplate.last :conditions => {:parent_id => nil}
      @new_template.name.should == 'Test Template'
      @new_template.child_templates.count.should == 1
    end
  end

  describe 'Apply Theme' do
    before(:each) do
      SiteTemplate.create_default_template

      @site_template.style_struct = '#space { size: 13px; }'
      @site_template.style_design = 'body { color: <cms:var name="font_color" type="color" default="#FFF"/>; }'
      @site_template.template_html = '<cms:zone name="Main"/> <cms:zone name="Sidebar"/>'
      @site_template.domain_file_id = DomainFile.create_folder('Test Theme').id
      @site_template.save
      @site_template.update_zones_and_options

      # Images
      @df = DomainFile.create(:filename => fixture_file_upload("files/rails.png",'image/png'), :parent_id => @site_template.domain_file_id)

      # Features
      @login_feature = @site_template.site_features.create :name => 'Login', :feature_type => 'login', :body => '<cms:logged_in>yes i am</cms:logged_in>'

      @site_template.reload

      @members_wizard = Wizards::MembersSetup.new :add_to_id => SiteVersion.current.root.id
      @simple_wizard = Wizards::SimpleSite.new :name => 'Test Site', :pages => ['Home', 'About']
    end

    after(:each) do
      @df.destroy
    end

    it "should be able to setup a site and apply the new theme" do
      @simple_wizard.run_wizard
      @members_wizard.run_wizard

      @site_template.apply_to_site SiteVersion.current, :features => true

      SiteVersion.current.root_node.reload
      SiteVersion.current.root_node.site_node_modifiers.find_by_modifier_type('template').options.template_id.should == @site_template.id

      @login_node = SiteNode.find_by_title('login')
      @login_node.should_not be_nil
      @login_node.live_revisions[0].page_paragraphs[0].site_feature_id.should == @login_feature.id
    end
  end

  it "should handle adding variables to the parent template" do
    @df = DomainFile.create(:filename => fixture_file_upload("files/rails.png",'image/png'), :parent_id => DomainFile.create_folder('Test Theme').id)

    @site_template.style_struct = '#space { size: <cms:var name="font_size" type="color" default="13px"/>; }'
    @site_template.style_design = 'body { color: <cms:var name="font_color" type="color" default="#FFF"/>; } .test { font-size: 12px; }'
    @site_template.template_html = '<cms:var name="title" trans="1" default="My Site"/> <cms:trans>Hi</cms:trans> <br/> <cms:zone name="Main"/> <cms:zone name="Sidebar"/> <cms:var name="title" type="string"/> <img src="images/rails.png"/> <cms:var name="zimage" type="image"/> <cms:var name="zimage2" type="image" default="rails.png"/>'
    @site_template.domain_file_id = @df.parent_id

    @site_template.save
    @site_template.update_zones_and_options
    @site_template.update_option_values 'zimage' => @df.id
    localize_values = {'en' => {'title' => 'my title'}}
    translate = {'en' => {0 => 'Hi'}}
    translations = {'en' => {0 => 'Hello'}}
    @site_template.set_localization localize_values, translate, translations
    @site_template.save


    @site_template.options[:options][0][0].should == 'font_color'
    @site_template.options[:options][1][0].should == 'font_size'
    @site_template.options[:options][2][0].should == 'title'
    @site_template.options[:options][3][0].should == 'zimage'
    @site_template.options[:options][4][0].should == 'zimage2'

    @site_template.options[:values]['font_color'].should == '#FFF'
    @site_template.options[:values]['font_size'].should == '13px'
    @site_template.options[:values]['title'].should == 'My Site'
    @site_template.options[:values]['zimage'].should == @df.id
    @site_template.options[:values]['zimage2'].should == @df.id

    # add a child template
    @child = SiteTemplate.create :name => 'Child Template Test', :parent_id => @site_template.id, :template_html => '<cms:var name="child var" default="child default value"/> <cms:zone name="Main"/> <cms:zone name="Sidebar"/>'

    @child.update_zones_and_options
    @child.save

    @child.reload
    @child.options[:options].empty?.should be_true
    @child.options[:values].empty?.should be_true

    @site_template.reload
    @site_template.update_zones_and_options
    @site_template.update_option_values nil
    @site_template.save

    @site_template.options[:options][0][0].should == 'child var'
    @site_template.options[:options][1][0].should == 'font_color'
    @site_template.options[:options][2][0].should == 'font_size'
    @site_template.options[:options][3][0].should == 'title'

    @site_template.options[:values]['font_color'].should == '#FFF'
    @site_template.options[:values]['font_size'].should == '13px'
    @site_template.options[:values]['title'].should == 'My Site'
    @site_template.options[:values]['child var'].should == 'child default value'
    @site_template.options[:values]['zimage'].should == @df.id
    @site_template.options[:values]['zimage2'].should == @df.id

    # add a feature
    @site_template.site_features.create :name => 'Login', :feature_type => 'login', :body => '<cms:var name="site feature var" default="default site feature var"/> <cms:logged_in>yes i am</cms:logged_in>'

    @site_template.reload
    @site_template.update_zones_and_options
    @site_template.update_option_values nil
    @site_template.save

    @site_template.options[:options][0][0].should == 'child var'
    @site_template.options[:options][1][0].should == 'font_color'
    @site_template.options[:options][2][0].should == 'font_size'
    @site_template.options[:options][3][0].should == 'site feature var'
    @site_template.options[:options][4][0].should == 'title'

    @site_template.options[:values]['font_color'].should == '#FFF'
    @site_template.options[:values]['font_size'].should == '13px'
    @site_template.options[:values]['title'].should == 'My Site'
    @site_template.options[:values]['child var'].should == 'child default value'
    @site_template.options[:values]['site feature var'].should == 'default site feature var'
    @site_template.options[:values]['zimage'].should == @df.id
    @site_template.options[:values]['zimage2'].should == @df.id

    SiteTemplate.render_template_css(@site_template.id, 'en', true).should == "#space { size: 13px; }body { color: #FFF; } .test { font-size: 12px; }"
    SiteTemplate.render_template_css(@site_template.id, 'en', 'struct').should == "#space { size: 13px; }"
    SiteTemplate.render_template_css(@site_template.id, 'en', false).should == "body { color: #FFF; } .test { font-size: 12px; }"

    @site_template.design_style_details('en', true).should == [["body", 1, [["color", "#FFF"]]], [".test", 1, [["font-size", "12px"]]]]
    @site_template.structural_style_details('en', true).should == [["#space", 1, [["size", "13px"]]]]

    @site_template.design_style_details('en', false).should == [["body", 1, [["color", "#FFF"]]], [".test", 1, [["font-size", "12px"]]]]
    @site_template.structural_style_details('en', false).should == [["#space", 1, [["size", "13px"]]]]

    SiteTemplate.css_styles(@site_template.id, 'en').should == ["#space", ".test", "body"]

    @child.css_id.should == @site_template.id
    @site_template.css_id.should == @site_template.id

    @parts = @site_template.render_html('en') {}
    @parts[0].variable.should == 'title'
    @parts[1].body.should == " Hello <br/> "
    @parts[1].zone_position.should == 1
    @parts[2].body.should == " "
    @parts[2].zone_position.should == 2
    @parts[3].body.should == " "
    @parts[3].variable.should == "title"
    @parts[4].body.should include("/rails.png")
    @parts[4].variable.should == "zimage"
    @parts[5].body.should == " "
    @parts[5].variable.should == "zimage2"
    @parts[6].body.should == ""

    @site_template.render_variable('title', nil, 'en').should == 'my title'
    @site_template.render_variable('font_color', nil, 'en').should == '#FFF'
    @site_template.render_variable('font_size', nil, 'en').should == '13px'
    @site_template.render_variable('zimage', nil, 'en').should == @df.image_tag

    @df.destroy
  end
end
