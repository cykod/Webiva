# Copyright (C) 2009 Pascal Rettig.

# Utility class parse CSS and return a list of tags
class Util::CssParser

  
  # Parses a string for the request elements and just return 
  # A list of elements as necessary
  def self.parse_names(css,type = ['classes','identifiers','elements'])
  # Remove Comments
    css = css.gsub(/\/\*.*?\*\//,'')
    
    parse_classes = type.include?('classes')
    parse_identifiers = type.include?('identifiers')
    parse_elements = type.include?('elements')
    
    # Now find any style classes that apply to any tag (i.e.: .classnmae { ... } )
    reg = /([^{]+)\{[^}]+\}/m
    styles = []
    css.scan(reg) do |match|
      match[0].split(',').each do |itm|
        itm = itm.strip
        if !itm.include?(' ') && !itm.empty?
          if itm[0..0] == '.'
            styles << itm if parse_classes
          elsif itm[0..0] == '#'
            styles << itm if parse_identifiers
          else
            styles << itm if parse_elements 
          end
        end
      end
    end
    
    styles  
  end
  
  # Parse the full CSS styles in a string 
  # and return an array of:
  # [ --Style name--, -Line Number-, [[atr1,val1],...]]
  def self.parse_full(css)
  
   # Now find any style classes that apply to any tag (i.e.: .classnmae { ... } )
    reg = /([^\n{]+)\{([^}]+)\}/m
    full_styles = []
    line = 1
    body  = css
    while( match = reg.match(body) ) 
      line += match.pre_match.count("\n")
      style_code = match[2].gsub("\n","").gsub("/*(.*?)*/","");
      style_styles = []
      style_code.split(";").each do |style|
        style.strip!
        style_name,style_val = style.split(":")
        if style_val
          style_name.strip!
          style_val.strip!
          style_styles << [ style_name, style_val ]
        end
      end
      
      match[1].split(',').each do |itm|
        itm = itm.strip
        if !itm.empty?
          full_styles << [ itm, line, style_styles ] 
        end
      end
      line += match[0].count("\n")
      body = match.post_match
    end
    
    full_styles
  end
  
  # Return a list of default styles for the parser
  def self.default_styles(css)
    default_style_names = ['*','body','html']
    ignore = %w(background background-color background-image)
    css.select do |style|
      default_style_names.include?(style[0])
    end.inject([]) { |memo,elm| memo + elm[2] }.select { |elm| !ignore.include?(elm[0]) }
  end
  
 
  
end
