# Copyright (C) 2009 Pascal Rettig.

require 'hpricot'

class Blog::BlogPostRevision < DomainModel

  validates_presence_of :title

  belongs_to :blog_post, :class_name => 'Blog::BlogPost', :foreign_key => 'blog_post_id'

  has_domain_file :domain_file_id
  has_domain_file :media_file_id
  
  apply_content_filter(:body => :body_html)  do |revision|
    { :filter => revision.blog_blog.content_filter,
      :folder_id => revision.blog_blog.folder_id
    }
  end

  apply_content_filter(:preview => :preview_html)  do |revision|
    { :filter => revision.blog_blog.content_filter,
      :folder_id => revision.blog_blog.folder_id
    }
  end

  attr_writer :blog_blog
  def blog_blog
    @blog_blog || self.blog_post.blog_blog
  end

  def body_content
    self.body_html.blank? ? self.body : self.body_html
  end
  
  def preview_content
    if self.preview.blank?
      body_content
    else
      self.preview_html.blank? ? self.preview : self.preview_html
    end
  end
  
 # Generate text from HTML
 def text_generator(html)
   link_sanitizer = HTML::LinkSanitizer.new
   link_sanitizer.sanitize(CGI::unescapeHTML(html.to_s.gsub(/\<\/(p|br|div)\>/," </\\1>\n ").gsub(/\<(h1|h2|h3|h4)\>(.*?)<\/(h1|h2|h3|h4)\>/) do |mtch|
        "\n#{$2}\n#{'=' * $2.length}\n\n"
    end.gsub("<br/>","\n")).gsub("&nbsp;"," "))
 end
   


 def ae_some_html(s)
    return if s.blank?
    
    s = strip_word(s)
    sanitizer = HTML::WhiteListSanitizer.new
    sanitizer.sanitize(s)
  end
  
  def strip_word(txt)
     cleanMso = Proc.new { |b| b = b.replace(/\bMso[\w\:\-]+\b/m, '') ? ' class="' + b + '"' : '' }
     
     regx = [  /^\s*( )+/m,                                              # nbsp entities at the start of contents
              /( |<br[^>]*>)+\s*$/m,                                     # nbsp entities at the end of contents
              /<!--\[(end|if)([\s\S]*?)-->|<style>[\s\S]*?<\/style>/mi,  # Word comments
              /<\/?(font|meta|link)[^>]*>/mi,                            # Fonts, meta and link
              /<\\?\?xml[^>]*>/mi,                                       # XML islands
              /<\/?o:[^>]*>/mi,                                          # MS namespaced elements <o:tag>
              /<\/?w:[^>]*>/mi,                                          # MS namespaced elements <o:tag>
              [/ class=\"([^\"]+)\"/mi, ''],                       # All classes like MsoNormal
              [/ class=([\w\:\-]+)/mi, ''],                        # All classes like MsoNormal
              / style=\"([^\"]+)\"| style=[\w\:\-]+/mi,                  # All style attributes
              [/<(\/?)s>/i, '<$1strike>']                              # Convert <s> into <strike> for line-though
                        ]
                        
      regx.each do |reg|
        if(reg.is_a?(Array))
          txt.gsub!(reg[0],reg[1])
        else
          txt.gsub!(reg,'')
        end
      end  
      
      
      txt                      
  end
end
