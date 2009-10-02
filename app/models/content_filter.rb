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
    code
  end

  def self.safe_html_filter(code,options={})
    @@sanitizer ||= HTML::WhiteListSanitizer.new
    @@sanitizer.sanitize(code)
  end

  def self.markdown_filter(code,options={})
    # Need file filter to output __fs__ stuff
    Maruku.new(code).to_html
  end

  def self.textile_filter(code,options={})
    # Need file filter to output __fs__ stuff
    RedCloth.new(code).to_html
  end

  def self.markdown_safe_filter(code,options={})
    @@sanitizer ||= HTML::WhiteListSanitizer.new
    @@sanitizer.sanitize(Maruku.new(code).to_html)
  end

  def self.comment_filter(code,options={})
    RedCloth.new(code,[:lite_mode, :filter_html]).to_html
  end

end
