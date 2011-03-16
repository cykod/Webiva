require  File.expand_path(File.dirname(__FILE__)) + "/../../../spec/spec_helper"

describe Util::TextFormatter do

  it "should be able to format a simple text table" do
  
    cols = [ 'Column A', 'Col B', '' ]
    
    data = [ 
            [ "Data Column A\nRow 2",'','Data Column C' ],
            [ 'Data','Data','Data  ' ]
           ]
           
    Util::TextFormatter.text_table(cols,data).should == <<EOF
-----------------------------------------
| Column A      | Col B |               |
-----------------------------------------
| Data Column A |       | Data Column C |
| Row 2         |       |               |
| Data          | Data  | Data          |
-----------------------------------------
EOF

  end  
  
  it "should be able to format a simple html table" do
     cols = [ 'Column A', 'Col B', '' ]
    
    data = [ 
            [ 'Data Column A','','Data Column C' ],
            [ 'Data','Data','Data  ' ]
           ]
           
    Util::TextFormatter.html_table(cols,data,:width => '100%').should == "<table width='100%'><thead><tr><th>Column A</th><th>Col B</th><th></th></tr></thead><tbody><tr><td>Data Column A</td><td></td><td>Data Column C</td></tr><tr><td>Data</td><td>Data</td><td>Data  </td></tr></tbody></table>"
  end
  
  it "should be able to unescape html" do
    Util::TextFormatter.unescape_html("&lt;").should == '<'
    Util::TextFormatter.unescape_html("&gt;").should == '>'
    Util::TextFormatter.unescape_html("&quot;").should == '"'
    Util::TextFormatter.unescape_html("<br>").should == "\n"
    Util::TextFormatter.unescape_html("<br/>").should == "\n"
    Util::TextFormatter.unescape_html("<BR/>").should == "\n"
    Util::TextFormatter.unescape_html("&nbsp;&NBSP;").should == '  '
    Util::TextFormatter.unescape_html("</p>").should == " </p>\n "
    Util::TextFormatter.unescape_html("</div>").should == " </div>\n "
    Util::TextFormatter.unescape_html("</DIV>").should == " </DIV>\n "
  end
  
  it "should be able to create plain text from html" do
    html =  "<p> <span class=\"h1\"><strong>Radiohead Photos</strong></span> <table width=\"400\" border=\"0\" align=\"center\" cellpadding=\"4\" cellspacing=\"4\">  <tr align=\"center\"> <td><img src=\"http://g-ec2.images-amazon.com/images/G/01/music/Radiohead_1_thumb.jpg\" width=\"125\" border=\"0\"></td>    <td> </td>     <td><img src=\"http://g-ec2.images-amazon.com/images/G/01/music/Radiohead_2_thumb.jpg\" width=\"125\" border=\"0\"></td> <td> </td>      </tr>    <tr align=\"center\">  <td><img src=\"http://g-ec2.images-amazon.com/images/G/01/music/Radiohead_3_thumb.jpg\" width=\"125\" border=\"0\"></td>     <td> </td>      <td><img src=\"http://g-ec2.images-amazon.com/images/G/01/music/Radiohead_Thom_4_thumb.jpg\" width=\"125\" border=\"0\"></td>  <td> </td>         </tr>   </table> <P> <P>   <span class=\"h1\"><strong>More from Radiohead</strong></span><BR> <span class=\"small\"></span>   <table width=\"100%\" border=\"0\" cellspacing=\"4\" cellpadding=\"4\">  <tr align=\"center\" valign=\"top\" class=\"small\">  <td width=\"33%\">   <img src=\"http://images.amazon.com/images/P/B000092ZYX.01.SWATCHZZ.jpg\" border=\"0\"><BR>  <i>Hail To The Thief</i></td>  <td width=\"33%\">  <img src=\"http://images.amazon.com/images/P/B000002TQV.01.SWATCHZZ.jpg\" border=\"0\"><BR>  <i>The Bends </i></td>  <td width=\"33%\">  <img src=\"http://images.amazon.com/images/P/B00004XONN.01.SWATCHZZ.jpg\" border=\"0\"><BR>  <i>Kid A</i></td></tr>   <tr> <tr align=\"center\" valign=\"top\" class=\"small\">  <td width=\"33%\">    <img src=\"http://images.amazon.com/images/P/B000002UR7.01.SWATCHZZ.jpg\" border=\"0\"><BR>  <i>Pablo Honey</i></td>  <td width=\"33%\">  <img src=\"http://images.amazon.com/images/P/B00005B4GU.01.SWATCHZZ.jpg\" border=\"0\"><BR>  <i>Amnesiac</i></td>  <td width=\"33%\">  <img src=\"http://images.amazon.com/images/P/B00005QXXO.01.SWATCHZZ.jpg\" border=\"0\"><BR>  <i>I Might Be Wrong: Live Recordings</i></td></tr>    </table>"
    
    Util::TextFormatter.text_plain_generator(html).should == "Radiohead Photos More from Radiohead\n\nHail To The Thief\nThe Bends\nKid A\nPablo Honey\nAmnesiac\nI Might Be Wrong: Live Recordings"
  end

  it "should be able to create plain text from html" do
    html =  "\n\n\n<br/><h1 class=\"title\"> Hello<br/>\n World\n</h1>\n \n <p>This is my story<br/></p> <BR>\n\n\n"
    
    Util::TextFormatter.text_plain_generator(html).should == "Hello\n\nWorld\n\nThis is my story"
  end

  it "should be able to create formatted text from html" do
    html =  "\n\n\n<br/><h1 class=\"title\"> Hello<br/>\n World\n</h1>\n \n <p>This is my story<br/></p> <BR>\n\n\n"
    Util::TextFormatter.text_formatted_generator(html).should == "Hello World\n===========\n\nThis is my story"
  end

  it "should be able to create formatted text from html" do
    html =  "\n\n\n<br/><h1 class=\"title\"> Hello<br/>\n World\n <span>(hi tester)</span></h1>\n \n <p>This is my story<br/></p> <BR>\n\n\n"
    Util::TextFormatter.text_formatted_generator(html).should == "Hello World (hi tester)\n=======================\n\nThis is my story"
  end
end
