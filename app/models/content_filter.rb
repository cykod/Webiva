# Copyright (C) 2009 Pascal Rettig.

require 'maruku'
require 'redcloth'

class ContentFilter < DomainModel


  @@built_in_filters = [ ['Full HTML','full_html'],
                         ['Safe HTML','safe_html'],
                         ['Markdown','markdown'],
                         ['Markdown Safe','markdown_safe'],
                         ['Textile','textile'],
                         ['Textile Safe','textfile_safe'],
                         ['Comment Filter','comment']
                         ]
  

  @@built_in_filter_hash = {}
  @@built_in_filters.each { |flt| @@built_in_filter_hash[flt[1]] = flt[0] }
  
  def self.filter_options
    @@built_in_filters.map { |elm| [ elm[0].t, elm[1] ] }
  end


  def self.filter(name,code,options={})
    name = name.to_s
    if @@built_in_filter_hash[name]
      return self.send("#{name}_filter",code,options)
    else
      raise 'Invalid Sanitizer'
    end
  end


  def self.full_html_filter(code,options={})
     # Need file filter to output __fs__ stuff
    if options[:folder_id] && folder = DomainFile.find_by_id(options[:folder_id])
      code = html_replace_images(code,folder.file_path)
    else
      code = html_replace_images(code,'')
    end
    code
  end

  def self.safe_html_filter(code,options={})
    @@sanitizer ||= HTML::WhiteListSanitizer.new
    @@sanitizer.sanitize(code)
  end

  def self.markdown_filter(code,options={})
    # Need file filter to output __fs__ stuff
    if options[:folder_id] && folder = DomainFile.find_by_id(options[:folder_id])
      code = markdown_replace_images(code,folder.file_path)
    else
      code = markdown_replace_images(code,'')
    end
    begin
      Maruku.new(code).to_html
    rescue
      "Invalid Markdown".t
    end
      
  end

  def self.textile_filter(code,options={})
    # Need file filter to output __fs__ stuff
    begin
      RedCloth.new(code).to_html
    rescue
      "Invalid Textile".t
    end
  end

  def self.markdown_safe_filter(code,options={})
    @@sanitizer ||= HTML::WhiteListSanitizer.new
    @@sanitizer.sanitize(Maruku.new(code).to_html)
  end

  def self.comment_filter(code,options={})
    RedCloth.new(code,[:lite_mode, :filter_html]).to_html
  end

  
  def self.markdown_replace_images(code,image_folder_path)
    cd =  code.gsub(/(\!?)\[([^\]]+)\]\(([^"')]+)/) do |mtch|
      img = $1
      alt_text = $2
      full_url = $3
      image_path,size = full_url.strip.split("::")
      if image_path =~ /^http(s|)\:\/\// && full_url[0..0] == '/'
        url = full_url
      else
        df = DomainFile.find_by_file_path(image_folder_path + "/" + image_path)
        url = df ? df.editor_url(size) :  "/images/site/missing_thumb.gif" 
      end
      "#{img}[#{alt_text}](#{url} "
    end

    cd
  end

  def self.html_replace_images(code,image_folder_path)

    re = Regexp.new("(['\"])images\/([a-zA-Z0-9_\\-\\/. :]+?)\\1" ,Regexp::IGNORECASE | Regexp::MULTILINE)
    cd =  code.gsub(re) do |mtch|
      wrapper = $1
      url = $2
      if url.include?(":")
        url,size = url.split(":")
      end
      df = DomainFile.find_by_file_path(image_folder_path + "/" + url)
      url = df ? df.editor_url(size) : "/images/site/missing_thumb.gif"
      "#{wrapper}#{url}#{wrapper}"
    end

    cd
  end

end
