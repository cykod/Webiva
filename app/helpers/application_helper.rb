# Copyright (C) 2009 Pascal Rettig.


# Base view helper
module ApplicationHelper

  include StyledFormBuilderGenerator::FormFor
  
  include EscapeHelper


  # Carry over from php (sorry)
  def nl2br(string)
    h(string).gsub("\n\r","<br>").gsub("\r", "").gsub("\n", "<br />")
  end   

  
  # Show a float number as a 2 decimal number
  def dec(number)
    number ? sprintf("%0.2f",number) : '0.00' 
  end
  
  # Adds a style='display:none;' unless the argument is true
  def hide_if(val)
    val ? "style='display:none;'" : ''
  end
  
  # Adds a style='display:none;' unless the argument is true
  def hide_unless(val)
    hide_if(!val)
  end
  

  # Simple pagination links
  def pagination(path,page_hash)
    
    display_pages = page_hash[:window_size].to_i
    page = page_hash[:page]
    pages = page_hash[:pages]
    
    result = ''
    
    if pages > 1
      
      # Show back button
      if page > 1
        result += "<a href='#{path}?page=#{page-1}'>&lt;&lt;</a> "
      end
      # Find out the first page to show
      start_page = (page - display_pages) > 1 ? (page - display_pages) : 1
      end_page = (start_page + (display_pages*2))
      if end_page > pages
        start_page -= end_page - pages - 1
        start_page = 1 if start_page < 1 
        
        end_page = pages
      end
      
      if start_page == 2
        result += " <a href='#{path}?page=1'> 1 </a> "
      elsif start_page > 2
        result += " <a href='#{path}?page=1'> 1 </a> .. "
      end
      
      (start_page..end_page).each do |pg|
        if pg == page
          result += " <b> #{pg} </b> "
        else
          result += " <a href='#{path}?page=#{pg}'> #{pg} </a> "
        end
      end
      
      if end_page == pages - 1
        result += " <a href='#{path}?page=#{pages}'> #{pages} </a> "
      elsif end_page < pages - 1
        result += " .. <a href='#{path}?page=#{pages}'> #{pages} </a> "
      end
      
      # Next Button
      if page < pages
        result += " <a href='#{path}?page=#{page+1}'>&gt;&gt;</a> "
      end
    end
    
    result  
    
  end



  # Show the number of days ago given a difference in seconds
  # from now
  def ago_format(sec_diff)
    min_diff = (sec_diff / 60).floor
    
    
    days_ago = (min_diff / (60 * 24)).floor
    min_diff = min_diff % (60 * 24)
    
    hours_ago = (min_diff / 60).floor
    min_ago = min_diff % 60
    
    output = ''
    if days_ago > 0
      output  << "%d day" / days_ago
      output << ", "
    end
    output << sprintf("%d:%02d",hours_ago,min_ago)
    
    output
  end

  # Displays themed stylesheet link
  def theme_stylesheet_link_tag(stylesheet,options={})
    stylesheet_link_tag "/themes/#{theme}/stylesheets/#{stylesheet}" ,options
  end

  def active_table_javascript # :nodoc:
  end

  # Displays an image from the active theme
  def theme_image_tag(img,options = {})
    options[:align] = 'absmiddle' unless options[:align]
    if img[0..6] == "/images"
      image_tag("/themes/#{theme}" + img,options)
    else
      image_tag("/themes/#{theme}/images/" + img,options)
    end
  end

  # Displays an image from the active theme
  # Used for future themes which might not have images
  def theme_icon(image_type,img,options={}) 
    options[:align] = 'absmiddle' unless options[:align]
    if img[0..6] == "/images"
      image_tag("/themes/#{theme}" + img,options)
    else
      image_tag("/themes/#{theme}/images/" + img,options)
    end
  end

  # Return the 2 character identifier for the current language
  def current_language
    session[:cms_language]
  end
  
  
  # Display an escaped value or a default value
  def v(val,empty_val = '-')
    if val.blank?
      empty_val
    else
      h(val)
    end
  end
  
  
  
  # Display a string with newlines as a ul
  def list_format(txt)
    "<ul>" + txt.split("\n").map { |elm| "<li>#{h elm}</l1>" }.join("\n") + "</ul>"
  end

  
  
end


