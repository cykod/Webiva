
class Blog::MultipleRssHandler

  def self.feed_rss_handler_info
    {
      :name => "Multiple Blogs RSS Feed"
    }
  end

  def initialize(options)
    @options = options
  end
  
  def get_feed
    limit = @options.limit > 0 ? @options.limit : 10
    
    posts = Blog::BlogPost.find(:all, :conditions => ['blog_blog_id IN(?) AND published_at < ? AND blog_posts.status="published"',@options.blogs,Time.now],
                                :include => :active_revision, :order => 'published_at DESC', :limit => limit)

    return nil if posts.empty?

    data = { :title => @options.feed_title,
             :description => @options.description,
             :link => Configuration.domain_link(@options.link_page_url),
             :items => []
           }

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

      item[:link] = Configuration.domain_link(post.content_node.link)
      item[:guid] = item[:link]
        
      if post.media_file
        item[:enclosure] = post.media_file
      end

      if post.domain_file
        item[:thumbnail] = post.domain_file
      end

      data[:items] << item
    end
      
    data
  end
  
  class Options < Feed::AdminController::RssModuleOptions
    attributes :blogs => [], :limit => 10, :full => false, :link_page_id => nil, :description => nil

    validates_presence_of :blogs, :limit, :link_page_id
    validates_numericality_of :limit

    integer_options :limit
    integer_array_options :blogs
    boolean_options :full
    page_options :link_page_id

    options_form(fld(:link_page_id, :page_selector, :label => 'Link'),
                 fld(:description, :text_area, :rows => 2),
                 fld(:blogs, :ordered_array, :options => :blogs_options),
		 fld(:limit, :text_field),
                 fld(:full, :yes_no)
		 )

    def blogs_options
      @blogs_options ||= Blog::BlogBlog.select_options
    end
  end
end
