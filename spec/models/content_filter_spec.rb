require File.dirname(__FILE__) + "/../spec_helper"


describe ContentFilter do

  reset_domain_tables :content_filter, :domain_files, :domain_file_instances

  it "should be able to return a list of filters" do
    filters = ContentFilter.filter_options
    filters.detect { |flter| flter[1] == 'markdown'}.should_not be_nil
    filters.detect { |flter| flter[1] == 'comment'}.should_not be_nil
  end

  it "should raise an issue if we try to passit an invalid filter" do
    Proc.new { 
    ContentFilter.filter("not_a_real_filter","testerama")
    }.should raise_error(RuntimeError)
  end

  

  @@full_xss_html = <<-HTML
<a href='javascript:XSSAttack();' onclick='XSSAttack2();'>Link...</a><br />
<p>Lorem ipsum, dolor sic amet!</p>
HTML

  @@escaped_xss_html = <<-HTML
<a>Link...</a><br />
<p>Lorem ipsum, dolor sic amet!</p>
HTML

  @@full_legit_html = <<-HTML
<h1>Header!</h1>
<a href="http://www.google.com">Google</a> is a search engine<br />
<p>Lorem ipsum, dolor sic amet!</p>
HTML

  @@full_image_html = <<-HTML
<h1>Header!</h1>
<a href="http://www.google.com">Google</a> is a search engine<br />
<p>Lorem ipsum, dolor sic amet!</p>
<img src='images/folder/rails.png'/>
HTML

 @@full_image_html_substibute = <<-HTML
<h1>Header!</h1>
<a href="http://www.google.com">Google</a> is a search engine<br />
<p>Lorem ipsum, dolor sic amet!</p>
<img src='IMAGE_SRC_HERE'/>
HTML

  describe "Full HTML Filter" do
  
    it "should let full html through unhindered" do
      ContentFilter.filter('full_html',@@full_xss_html).should == @@full_xss_html
    end

    it "should do image substitution with editor urls" do
      @folder= DomainFile.create_folder('folder')
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @df = DomainFile.create(:filename => fdata,:parent_id => @folder.id)
      ContentFilter.filter('full_html',@@full_image_html).should ==  @@full_image_html_substibute.gsub('IMAGE_SRC_HERE',@df.editor_url)
      @df.destroy
    end

    it "should support live filter substitution" do
      @folder= DomainFile.create_folder('folder')
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @df = DomainFile.create(:filename => fdata,:parent_id => @folder.id)
      ContentFilter.live_filter('full_html',@@full_image_html).should ==  @@full_image_html_substibute.gsub('IMAGE_SRC_HERE',@df.url)
      @df.destroy
    end

  end

  describe "Safe HTML Filter" do
    
    it "should escape safe html and get rid of basic XSS" do
      ContentFilter.filter('safe_html',@@full_xss_html).should == @@escaped_xss_html
    end

    it "should let legit html through" do
      ContentFilter.filter('safe_html',@@full_legit_html).should == @@full_legit_html
    end

    
  end

  @@markdown_sample = <<-MARKDOWN
Header One
==========

This is a test of the emergency broadcast system,
this is only a test.

Lorem McIpsum

Header Two
----------

Something Else

* Item 1
* Item 2
* Item 3

<a href='javascript:XSSAttack();'>Normal Link</a>

MARKDOWN

  # need to strip so we don't get a trailing \n
  @@markdown_sample_translated_full = (<<-MARKDOWN).strip
<h1 id='header_one'>Header One</h1>

<p>This is a test of the emergency broadcast system, this is only a test.</p>

<p>Lorem McIpsum</p>

<h2 id='header_two'>Header Two</h2>

<p>Something Else</p>

<ul>
<li>Item 1</li>

<li>Item 2</li>

<li>Item 3</li>
</ul>
<a href='javascript:XSSAttack();'>Normal Link</a>
MARKDOWN

  # need to strip so we don't get a trailing \n
  @@markdown_sample_translated_safe = (<<-MARKDOWN).strip
<h1>Header One</h1>

<p>This is a test of the emergency broadcast system, this is only a test.</p>

<p>Lorem McIpsum</p>

<h2>Header Two</h2>

<p>Something Else</p>

<ul>
<li>Item 1</li>

<li>Item 2</li>

<li>Item 3</li>
</ul>
<a>Normal Link</a>
MARKDOWN
  
  
 @@markdown_image_sample = <<-MARKDOWN
This is a test of the emergency broadcast system,
this is only a test ![My Image](images/myfolder/rails.png)

MARKDOWN
  describe "Markdown Filter" do

    it "should be able to translate basic markdown" do
      ContentFilter.filter('markdown',@@markdown_sample).should == @@markdown_sample_translated_full
    end


    it "should be able to do file replacement" do 
      @folder= DomainFile.create_folder('myfolder')
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @df = DomainFile.create(:filename => fdata,:parent_id => @folder.id)
      ContentFilter.filter('markdown',@@markdown_image_sample).should ==
        "<p>This is a test of the emergency broadcast system, this is only a test <img src='#{@df.editor_url}' alt='My Image' /></p>"
      @df.destroy

    end
  end

  describe "Markdown Safe Filter" do

    it "should be able to translate basic markdown safely" do
      ContentFilter.filter('markdown_safe',@@markdown_sample).should == @@markdown_sample_translated_safe
    end

  end

  @@comment_sample = <<-COMMENT
Comments should
ignore paragraphs

__Italics Test__
*Bold Test**
<a href='http://www.google.com'>Google Link</a>
<a onclick='XSSExecute();' href='http://www.google.com'>XSS Link</a>
COMMENT

  @@comment_sample_escaped = <<-COMMENT
Comments should<br />
ignore paragraphs<br />
<br />
<i>Italics Test</i><br />
<strong>Bold Test</strong>*<br />
&lt;a href='<a href=\"http://www.google.com'&gt;Google\" rel=\"nofollow\" target=\"_blank\">http://www.google.com'&amp;gt;Google</a> Link&lt;/a&gt;<br />
&lt;a onclick='XSSExecute();' href='<a href=\"http://www.google.com'&amp;gt\" rel=\"nofollow\" target=\"_blank\">http://www.google.com'&amp;gt</a>;<span class=\"caps\">XSS</span> Link&lt;/a&gt;<br />
COMMENT

  describe "Comment Filter" do
    it "should be able to escape html syntax" do
      ContentFilter.filter('comment',@@comment_sample).should == @@comment_sample_escaped
    end
  end


@@textile_sample = <<-TEXTILE
h1. Header

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce accumsan pellentesque arcu,
sit amet sollicitudin purus porttitor placerat. Curabitur aliquam, tellus eget varius semper,
sapien eros rhoncus massa, ac sollicitudin urna lectus sed eros. Sed in massa lectus,
nec fringilla mi. Quisque sed sapien enim. "Google":http://www.google.com
!images/textilefolder/rails.png:thumb!
<a href='javascript:XSSAttack!'>Go</a>

TEXTILE

@@textile_translated = <<-TEXTILE
<h1>Header</h1>
<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce accumsan pellentesque arcu,<br />
sit amet sollicitudin purus porttitor placerat. Curabitur aliquam, tellus eget varius semper,<br />
sapien eros rhoncus massa, ac sollicitudin urna lectus sed eros. Sed in massa lectus,<br />
nec fringilla mi. Quisque sed sapien enim. <a href=\"http://www.google.com\">Google</a><br />
<img src="IMAGE_TAG_HERE" alt="" /><br />
<a href='javascript:XSSAttack!'>Go</a></p>
TEXTILE

@@textile_translated_safe = <<-TEXTILE
<h1>Header</h1>
<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce accumsan pellentesque arcu,<br />
sit amet sollicitudin purus porttitor placerat. Curabitur aliquam, tellus eget varius semper,<br />
sapien eros rhoncus massa, ac sollicitudin urna lectus sed eros. Sed in massa lectus,<br />
nec fringilla mi. Quisque sed sapien enim. <a href=\"http://www.google.com\">Google</a><br />
<img src="images/textilefolder/rails.png:thumb" alt="" /><br />
<a>Go</a></p>
TEXTILE

  describe "Textile Filter" do
    it "should able to filter text" do
      @folder= DomainFile.create_folder('textilefolder')
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @df = DomainFile.create(:filename => fdata,:parent_id => @folder.id)
      ContentFilter.filter('textile',@@textile_sample).should == @@textile_translated.gsub("IMAGE_TAG_HERE",@df.editor_url(:thumb)).strip
    end

    it "should be able safely filter text" do
        ContentFilter.filter('textile_safe',@@textile_sample).should == @@textile_translated_safe.strip
    end
  end

end
