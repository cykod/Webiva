# Copyright (C) 2009 Pascal Rettig.

module TemplatesHelper #:nodoc:all

  def merge_style(css_style,styles)
    # Try to fake the Cascading part of CSS by seeing if any other styles 
    styles = styles.select  { |style| css_style[0].starts_with?(style[0]) && ["."," ",":"].include?(css_style[0][style[0].length..style[0].length])  }
    styles.inject([]) { |memo,style| memo += style[2] } + css_style[2]
  end

  def display_style(css_styles) 
    return "" unless css_styles
    ok_styles = %w(color font font-size font-family font-weight background-color background border border-top border-bottom border-left border-right)
    
    output = []
    css_styles.each do |style|
      output << "#{style[0]}:#{style[1]};" if ok_styles.include?(style[0])
    end
    output.join(" ")
  end
  
end
