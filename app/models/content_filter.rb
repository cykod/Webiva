# Copyright (C) 2009 Pascal Rettig.

require 'maruku'
require 'redcloth'


=begin rdoc
ContentFilter represents the beginning of configurable content filter support
in Webiva. Currently it only supports the built in filters, but eventually support
will be added for additional customizable filters allowing token substitution.

You can filter content by calling the filter class method with the name of the filter
and the text that needs to be filtered.

Example:

    ContentFilter.filter('markdown',@code)

=end
class ContentFilter < DomainModel

  class << self;
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::UrlHelper
  end

  @@built_in_filters = [ ['Full HTML','full_html'],
                         ['Safe HTML','safe_html'],
                         ['Markdown','markdown'],
                         ['Markdown Safe','markdown_safe'],
                         ['Textile','textile'],
                         ['Textile Safe','textile_safe'],
                         ['Comment Filter','comment']
                         ]
  

  @@built_in_filter_hash = {}
  @@built_in_filters.each { |flt| @@built_in_filter_hash[flt[1]] = flt[0] }
  
  # Return a select-friendly list of filters
  def self.filter_options
    @@built_in_filters.map { |elm| [ elm[0].t, elm[1] ] }
  end

  # Return a select-friendly list of user safe filters
  def self.safe_filter_options
    @@built_in_filters.select {  |elm| elm[1].include?('safe') || elm[1] == 'comment'}.map { |elm| [ elm[0].t, elm[1] ] }
  end


=begin rdoc
Run the named filter on the passed in code, will output editor url
file replacements which must be run through the file instance editor
(this is done automatically if you are using the content_model model extensions)

If you want a user usable output (with full /system/storage/... file paths),
use self.live_filter or pass the :live_url option

Options:

 [:pre_filter]
 Proc to run on the code before the filter is run
 [:post_filter]
 Proc to run on the code after the filter is run
 [:folder_id]
 DomainFile id to use as the base for any image/link replacement
 [:live_url]
 Don't generate editor url links (__fs__/...) but full web-usable links
=end
  def self.filter(name,code,options={})
    name = name.to_s
    if @@built_in_filter_hash[name]
      
      # Pre-filter Proc
      code = options[:pre_filter].call(code) if options[:pre_filter]

      # Do the actual filtering
      code = self.send("#{name}_filter",code,options)

      # Post filter proc
      code = options[:post_filter].call(code)  if options[:post_filter]

      code
    else
      raise 'Invalid Sanitizer'
    end
  end

  def self.live_filter(name,code,options={})
    code = self.filter(name,code,options.merge(:live_url => true))
  end


  def self.full_html_filter(code,options={}) #:nodoc:
     # Need file filter to output __fs__ stuff
    if options[:folder_id] && folder = DomainFile.find_by_id(options[:folder_id])
      code = html_replace_images(code,folder.file_path,options[:live_url])
    else
      code = html_replace_images(code,'',options[:live_url])
    end
    code
  end

  def self.safe_html_filter(code,options={}) #:nodoc:
    @@sanitizer ||= HTML::WhiteListSanitizer.new
    @@sanitizer.sanitize(code)
  end

  def self.markdown_filter(code,options={}) #:nodoc:
    # Need file filter to output __fs__ stuff
    if options[:folder_id] && folder = DomainFile.find_by_id(options[:folder_id])
      code = markdown_replace_images(code,folder.file_path,options[:live_url])
    else
      code = markdown_replace_images(code,'',options[:live_url])
    end
    begin
      Maruku.new(code).to_html
    rescue
      "Invalid Markdown".t
    end
      
  end

  def self.textile_filter(code,options={}) #:nodoc:
    # Need file filter images/ links and images
    if options[:folder_id] && folder = DomainFile.find_by_id(options[:folder_id])
      code = textile_replace_images(code,folder.file_path,options[:live_url])
    else
      code = textile_replace_images(code,'',options[:live_url])
    end
    begin
      RedCloth.new(code).to_html
    rescue
      "Invalid Textile".t
    end
  end

  def self.textile_safe_filter(code,options={ })
    begin
      @@sanitizer ||= HTML::WhiteListSanitizer.new
      safe_link(@@sanitizer.sanitize(RedCloth.new(code).to_html))
    rescue
      "Invalid Textile".t
    end
  end

  def self.markdown_safe_filter(code,options={}) #:nodoc:
    @@sanitizer ||= HTML::WhiteListSanitizer.new
    safe_link(@@sanitizer.sanitize(Maruku.new(code).to_html))
  end

  def self.comment_filter(code,options={}) #:nodoc:
    safe_link(RedCloth.new(code,[:lite_mode, :filter_html]).to_html).gsub(/^([ ]+)/) { "&nbsp;" * $1.length }
  end

  def self.safe_link(code)
    auto_link(code,  :html => { :target => '_blank', :rel => 'nofollow' } )
  end
  
  def self.markdown_replace_images(code,image_folder_path,live_url = false) #:nodoc:
    cd =  code.gsub(/(\!?)\[([^\]]+)\]\(images\/([^"')]+)/) do |mtch|
      img = $1
      alt_text = $2
      full_url = $3
      image_path,size = full_url.strip.split("::")
      if image_path =~ /^http(s|)\:\/\// || full_url[0..0] == '/'
        url = full_url
      else
        df = DomainFile.find_by_file_path(image_folder_path + "/" + image_path,:conditions => {  :private => false })
        url = df ? (live_url ? df.url(size) : df.editor_url(size)) :  "/images/site/missing_thumb.gif" 
      end
      "#{img}[#{alt_text}](#{url} "
    end

    cd
  end


  def self.wysiwyg_replace_images(html) 
    html = html.gsub(/\/__fs__\/([0-9a-fA-F\/]+)(\:([a-zA-Z_]+)){0,1}/) do |match|
      size = $3 ? $3 : nil
      file_id = $1.split("/")[-1].to_i
      file = DomainFile.find_by_id(file_id)
      if file
        file.url(size)
      else
        "/images/missing_image.gif"
      end
    end

  end

 def self.html_replace_images(code,image_folder_path,live_url = false) #:nodoc:

    re = Regexp.new("(['\"])images\/([a-zA-Z0-9_\\-\\/. :]+?)\\1" ,Regexp::IGNORECASE | Regexp::MULTILINE)
    cd =  code.gsub(re) do |mtch|
      wrapper = $1
      url = $2
      if url.include?(":")
        url,size = url.split(":")
      end
      df = DomainFile.find_by_file_path(image_folder_path + "/" + url)
      url = df ?  (live_url ? df.url(size) : df.editor_url(size))  : "/images/site/missing_thumb.gif"
      "#{wrapper}#{url}#{wrapper}"
    end

    cd
  end


  def self.textile_replace_images(code,image_folder_path,live_url = false) #:nodoc:

    re = Regexp.new("(\!|\:)images\/([a-zA-Z0-9_\\-\\/. :]+)" ,Regexp::IGNORECASE | Regexp::MULTILINE)
    cd =  code.gsub(re) do |mtch|
      prefix = $1
      url = $2
      if url.include?(":")
        url,size = url.split(":")
      end
      df = DomainFile.find_by_file_path(image_folder_path + "/" + url,:conditions => {  :private => false })
      url = df ?  (live_url ? df.url(size) : df.editor_url(size)) : "/images/site/missing_thumb.gif"
      "#{prefix}#{url}"
    end

    cd
  end

end
