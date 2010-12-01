# Copyright (C) 2009 Pascal Rettig.


class Blog::RssHandler

  def self.feed_rss_handler_info
    {
    :name => "Blog RSS Feed"
    }
  end

  def initialize(options)
    @options = options
    @feed_id = @options.feed_identifier
    @feed_site_node,@feed_blog_id,@detail_page_id = @feed_id.split(",")
  end
  
  def get_feed
    @node = SiteNode.find_by_id(@feed_site_node)
    @blog = Blog::BlogBlog.find_by_id(@feed_blog_id)
    @detail_page = SiteNode.find_by_id(@detail_page_id)
    
    limit = @options.limit > 0 ? @options.limit : 10
    
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
                 :description => Util::HtmlReplacer.replace_relative_urls(@options.full ? post.body_content : post.preview)
                }
        item[:creator] = post.author unless post.author.blank?
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

        if post.domain_file
          item[:thumbnail] = post.domain_file
        end

        data[:items] << item
      end
      
      data
    else
      nil
    end
  end
  
  class Options < Feed::AdminController::RssModuleOptions
    attributes :feed_identifier => nil, :limit => 10, :full => false

    validates_presence_of :feed_identifier, :limit
    validates_numericality_of :limit

    integer_options :limit

    options_form(fld(:feed_identifier, :select, :options => :feed_identifier_options, :label => 'Feed'),
		 fld(:limit, :text_field),
     fld(:full,:yes_no)
		 )

    def validate
      if self.feed_identifier
	errors.add(:feed_identifier) unless self.feed_identifier_options.rassoc(self.feed_identifier)
      end
    end

    def feed_identifier_options
      revisions = PageRevision.find(:all,:joins => :page_paragraphs,
				    :conditions => 'display_module = "/blog/page" AND display_type = "entry_list" AND page_revisions.active=1 AND revision_type="real"')
      opts = [['--Select Feed--', nil]]
    
      revisions.each do |rev|
        par = rev.page_paragraphs.detect { |p| p.display_module =='/blog/page' && p.display_type == 'entry_list' }
        blog = Blog::BlogBlog.find_by_id(par.data[:blog_id]) if par
        detail_page = par.data[:detail_page] if par && par.data[:detail_page]

        if par && blog && rev.revision_container.is_a?(SiteNode)
          opts << [ blog.name + ' - ' + rev.revision_container.node_path, "#{rev.revision_container_id},#{blog.id},#{detail_page}" ]
        end
      end
      opts
    end
  end

end
