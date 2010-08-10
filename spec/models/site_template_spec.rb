require File.dirname(__FILE__) + "/../spec_helper"

describe SiteTemplate do

  reset_domain_tables :editor_changes,  :site_feature, :site_template, :domain_file, :site_template_zone, :site_template_rendered_part

  
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
    design_part.body.should == "body { color: #ff0000; }\n"
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
end
