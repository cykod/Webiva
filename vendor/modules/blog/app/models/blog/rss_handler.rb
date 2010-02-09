# Copyright (C) 2009 Pascal Rettig.


class Blog::RssHandler

  def self.feed_rss_handler_info
    {
    :name => "Blog RSS Feed"
    }
  end

  def initialize(feed_id,options)
    @options = options
    @feed_id = feed_id
    @feed_site_node,@feed_blog_id,@detail_page_id = feed_id.split(",")
  end
  

  def self.get_feed_options
    revisions = PageRevision.find(:all,:joins => :page_paragraphs,
                       :conditions => 'display_module = "/blog/page" AND display_type = "entry_list" AND page_revisions.active=1 AND revision_type="real"')
                       
    opts = []
    
    revisions.each do |rev|
      par = rev.page_paragraphs[0]
      blog = Blog::BlogBlog.find_by_id(par.data[:blog_id]) if par
      detail_page = par.data[:detail_page] if par && par.data[:detail_page]
      
      if par && blog && rev.revision_container.is_a?(SiteNode)
        opts << [ blog.name + ' - ' + rev.revision_container.node_path, "#{rev.revision_container_id},#{blog.id},#{detail_page}" ]
      end
    end
    opts
  end

  # options limit => 10
  def get_feed(options = {})

    feature_output = Blog::BlogBlog.cache_fetch("RSS_#{@feed_id}", @feed_blog_id.to_i)
    
    return feature_output if feature_output
    

  
    @node = SiteNode.find_by_id(@feed_site_node)
    @blog = Blog::BlogBlog.find_by_id(@feed_blog_id)
    @detail_page = SiteNode.find_by_id(@detail_page_id)
    
    limit = options.delete(:limit) || 10
    
    if @node && @blog
      data = { :title => @blog.name,
               :description => @blog.name,
               :link => Configuration.domain_link(@node.node_path),
               :items => []}
      posts = @blog.blog_posts.find(:all, :conditions => ['published_at < ? AND blog_posts.status="published"',Time.now], :include => :active_revision,
                                    :order => 'published_at DESC', :limit => limit)
      
      posts.each do |post|
        item = { :title => post.title,
                 :guid => post.id,
                 :published_at => post.published_at.to_s(:rfc822),
                 :description => replace_relative_urls(post.preview)
                }
        post.blog_categories.each do |cat|
          item[:categories] ||= []
          item[:categories] << cat.name
        end
        if @detail_page
          item[:link] = Configuration.domain_link(@detail_page.node_path + "/" +  post.permalink)
          item[:guid] = item[:link]
        end
        
        if post.media_file
          item[:enclosure] = post.media_file
        end

        data[:items] << item
      end
      
      @blog.cache_put("RSS_#{@feed_id}", data)
      data
    else
      nil
    end
  end
  
  def replace_relative_urls(txt)
    replace_image_sources(replace_link_hrefs(txt))
  end

 @@src_href = /\<img([^\>]+?)src\=(\'|\")([^\'\"]+)(\'|\")([^\>]*?)\>/mi 
 def replace_image_sources(txt)
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
 def replace_link_hrefs(txt)
   txt.gsub(@@href_regexp) do |mtch|
      href=$3
      # Only replace absolute urls
      if href[0..0] == '/'
	href = "http://" + Configuration.full_domain + href
      end
    "<a#{$1}href='#{href}'#{$5} target='_blank'>"
    end
 end 

end
