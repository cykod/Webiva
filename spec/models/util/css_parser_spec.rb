require File.dirname(__FILE__) + "/../../spec_helper"

describe Util::CssParser do
  
  before(:each) do
    @styles = <<-CSS
     /* This is a comment */
      .funny { 
        color: #CCCCCC;
        font-size:12px; 
      }
      
      
      h3,h4 { font-size:20px; padding:0px; color:red; }
    CSS
  
    @parsed_styles = [ [ '.funny', 2, [['color','#CCCCCC'],['font-size','12px']] ],
                      [ 'h3',8, [['font-size','20px'],['padding','0px'],['color','red']] ],
                      [ 'h4',8, [['font-size','20px'],['padding','0px'],['color','red']] ],
                      [ '*',10, [['font-size','20px']] ],
                      [ 'body',12, [['color','red']] ] ]
                      
  end

  it "should parse the full styles from a css string" do
    
    styles = Util::CssParser.parse_full(@styles)
    styles.should ==[ [ '.funny', 2, [['color','#CCCCCC'],['font-size','12px']] ],
                      [ 'h3',8, [['font-size','20px'],['padding','0px'],['color','red']] ],
                      [ 'h4',8, [['font-size','20px'],['padding','0px'],['color','red']] ] ]
  end
  
  it "should parse design style class names from a css string" do
    styles = Util::CssParser.parse_names(@styles,['classes'])
    styles.should == ['.funny']
  end
  
  it "should parse just elements" do
    styles = Util::CssParser.parse_names(@styles,['elements'])
    styles.should == ['h3','h4']
  end


  it "should parse everything" do
    styles = Util::CssParser.parse_names(@styles)
    styles.should == ['.funny', 'h3','h4']
  end
  
  it "should return a list of default styles" do
    styles = Util::CssParser.default_styles(@parsed_styles)
    styles.should == [['font-size','20px'],['color','red']]
  end
  
end
