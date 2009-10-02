require File.dirname(__FILE__) + "/../spec_helper"


describe ContentFilter do

  reset_domain_tables :content_filter

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

  describe "Full HTML Filter" do
  
    it "should let full html through unhindered" do
      ContentFilter.filter('full_html',@@full_xss_html).should == @@full_xss_html
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
  
  
  describe "Markdown Filter" do

    it "should be able to translate basic markdown" do
      ContentFilter.filter('markdown',@@markdown_sample).should == @@markdown_sample_translated_full
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
&lt;a href='http://www.google.com'&gt;Google Link&lt;/a&gt;<br />
&lt;a onclick='XSSExecute();' href='http://www.google.com'&gt;<span class=\"caps\">XSS</span> Link&lt;/a&gt;<br />
COMMENT

  describe "Comment Filter" do
    it "should be able to escape html syntax" do
      ContentFilter.filter('comment',@@comment_sample).should == @@comment_sample_escaped
    end
  end

end
