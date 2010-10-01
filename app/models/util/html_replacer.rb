
class Util::HtmlReplacer
  def self.replace_relative_urls(txt)
    self.replace_image_sources(self.replace_link_hrefs(txt))
  end

  @@src_href = /\<img([^\>]+?)src\=(\'|\")([^\'\"]+)(\'|\")([^\>]*?)\>/mi 
  def self.replace_image_sources(txt)
    txt.to_s.gsub(@@src_href) do |mtch|
      src=$3
      # Only replace absolute urls
      if src[0..0] == '/'
        src = "http://" + Configuration.full_domain + src
      end
      "<img#{$1} src='#{src}'#{$5}>"
    end
  end
 
 
  @@href_regexp = /\<a([^\>]+?)href\=(\'|\")([^\'\"]+)(\'|\")([^\>]*?)\>/mi
  # Replace all site links with full http:// links
  # Only necessary if not tracking links
  def self.replace_link_hrefs(txt)
    txt.to_s.gsub(@@href_regexp) do |mtch|
      href=$3
      # Only replace absolute urls
      if href[0..0] == '/'
	href = "http://" + Configuration.full_domain + href
      end
      "<a#{$1}href='#{href}'#{$5} target='_blank'>"
    end
  end
end
