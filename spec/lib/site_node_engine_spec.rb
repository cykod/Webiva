require File.dirname(__FILE__) + "/../spec_helper"

describe SiteNodeEngine, :type => :controller do
  controller_name :page

  integrate_views

  @@html_test_code = "<h1>Yo, Html Paragraph here!</h1>"
  @@code_test_code = "<h1>Yo, Code Paragraph here!</h1>"

  reset_domain_tables :end_users, :site_versions, :page_revisions, :site_nodes, :site_node_modifiers, :page_paragraphs, :site_templates, :site_template_rendered_parts,  :site_template_zones

  
  before(:each) do

    @site_template = SiteTemplate.create(:name => 'Test Template',:template_html => '<div class="container"><cms:zone name="main"/></div>')
    
    @page = SiteVersion.default.root_node.add_subpage('test_page')
    @paragraph1 =  @page.live_revisions[0].page_paragraphs.create(:display_type => 'html',:display_body => @@html_test_code,:zone_idx => 1, :position => 2)
    @paragraph2 = @page.live_revisions[0].page_paragraphs.create(:display_type => 'code',:display_body => @@code_test_code, :zone_idx => 1, :position => 1)

    @page.reload

    @user = EndUser.push_target('svend@karlson.com')
  end
  
  it "should be able to find a page from path" do
    @found_page, @args = controller.send(:find_page_from_path,['test_page','something_else','and_one_more'],SiteVersion.default.id)
    
    @found_page.should == @page
    @args.should == ['something_else','and_one_more']
  end

  it "should return a 404 on invalid page args" do
    
    engine = SiteNodeEngine.new(@page,:path => ['extra_args' ])

    Proc.new { 
      @output = engine.run(controller,@user)
    }.should raise_error(SiteNodeEngine::MissingPageException)

  end
  
  it "should render the page if the args are correct" do
    
    engine = SiteNodeEngine.new(@page,:path => [])

    @output = engine.run(controller,@user)

    @output.class.to_s.should == 'SiteNodeEngine::PageOutput'
    @output.page?.should be_true

    text = controller.send(:render_output,@page,@output)
    text.should == "<div class=\"container\"><div class='code_paragraph'><h1>Yo, Code Paragraph here!</h1></div><div class='html_paragraph'><h1>Yo, Html Paragraph here!</h1></div></div>"

  end

  it "basic output should return false for all tests" do 
    @output =  SiteNodeEngine::Output.new
    @output.redirect?.should be_false
    @output.document?.should be_false
    @output.page?.should be_false
    
  end
  
  it "should return a redirect if we have a J node" do
    
    @redirect_page = @page.add_subpage('jumper','J')
    @redirect_page.redirect_detail.redirect_type = 'external'
    @redirect_page.redirect_detail.redirect_url ='http://www.google.com'
    
    engine = SiteNodeEngine.new(@redirect_page,:path => [])

    @output = engine.run(controller,@user)
    @output.redirect.should be_true

    @output.class.to_s.should == 'SiteNodeEngine::RedirectOutput'

    @output.redirect.should == "http://www.google.com"
  end

  it "should return a document if we have a document node" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    
    @df = DomainFile.create(:filename => fdata)

    @document_page = @page.add_subpage('documenter','D')
    @document_page.node_data = @df.id
    @document_page.save

    engine = SiteNodeEngine.new(@document_page,:path => [])

    @output = engine.run(controller,@user)

    @output.class.to_s.should == 'SiteNodeEngine::DocumentOutput'

    @output.file?.should be_false
    @output.file.should be_nil
    @output.data.should be_nil
    @output.text?.should  be_false
    @output.text.should be_nil
    @output.document?.should be_true

    @df.destroy
  end
  
  it "should raise a missing page exception if we don't have an active version" do
    @page.live_revisions[0].update_attributes(:active => false)

    engine = SiteNodeEngine.new(@page,:path => [])
    
    Proc.new { 
      @output = engine.run(controller,@user)
    }.should raise_error(SiteNodeEngine::NoActiveVersionException)
 
  end

  it "should be able to run an individual paragraph if it's ajax" do

    engine = SiteNodeEngine.new(@page,:path => [])

    @paragraph1.should_receive(:info).and_return({ :ajax => true})
    @output = engine.run_paragraph(@paragraph1,controller,@user)

    @output.class.to_s.should == 'ParagraphRenderer::ParagraphOutput'
  end

  it "shouldn't be able to run an individual paragraph if it's not ajax" do

    engine = SiteNodeEngine.new(@page,:path => [])

    @paragraph1.should_receive(:info).and_return({})
    Proc.new { 
      @output = engine.run_paragraph(@paragraph1,controller,@user)
    }.should raise_error(RuntimeError)

  end

  it "should be able to render a menu and a login box" do 
    rev = @page.live_revisions[0]



    @paragraph3 =  rev.page_paragraphs.create(:display_type => 'login',
                                              :display_module => '/editor/auth',
                                              :zone_idx => 1, 
                                              :position => 3)
    @paragraph4 = rev.page_paragraphs.create(:display_type => 'automenu',
                                             :display_module => '/editor/menu',
                                             :zone_idx => 1, 
                                             :position => 4,
                                             :data => { 
                                               :root_page => @page.id,
                                               :levels => 1
                                             })
    engine = SiteNodeEngine.new(@page,:path => [])
    @output = engine.run(controller,@user)

    @output.class.to_s.should == 'SiteNodeEngine::PageOutput'
    @output.page?.should be_true
    
    text = controller.send(:render_output,@page,@output)

  end


end
