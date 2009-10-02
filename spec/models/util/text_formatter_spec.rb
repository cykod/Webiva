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
end
