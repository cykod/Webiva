# Copyright (C) 2009 Pascal Rettig.


class Blog::BlogBlog < DomainModel

  validates_presence_of :name
  validates_presence_of :content_filter

  belongs_to :target, :polymorphic => true

  has_many :blog_posts, :dependent => :destroy
  has_many :blog_categories, :class_name => 'Blog::BlogCategory', :dependent => :destroy, :order => 'blog_categories.name'

  cached_content # Add cached content support 

  attr_accessor :add_to_site

  include SiteAuthorizationEngine::Target
  access_control :edit_permission
  
  serialize :options
  
  content_node_type :blog, "Blog::BlogPost", :content_name => :name,:title_field => :title, :url_field => :permalink # Or field_name or Proc.new
  
  def self.create_user_blog(name,target)
    self.create(:name => name, :target => target, :is_user_blog => true)
  end

  def content_admin_url(blog_entry_id)
    {  :controller => '/blog/manage', :action => 'post', :path => [ self.id, blog_entry_id ],
       :title => 'Edit Blog Entry'.t}
  end


  def paginate_posts_by_category(page,cat,items_per_page)
    Blog::BlogPost.paginate(page,
                            :include => [ :active_revision, :blog_categories ],
                            :order => 'published_at DESC',
                            :conditions => ["blog_posts.status = \"published\" AND blog_posts.published_at < ? AND blog_posts.blog_blog_id=? AND blog_categories.name = ?",Time.now,self.id, cat],
                            :per_page => items_per_page)
  end                       


  def paginate_posts_by_tag(page,cat,items_per_page)
    Blog::BlogPost.paginate(page,
                            :include => [ :active_revision, :content_tags ],
                            :order => 'published_at DESC',
                            :conditions => ["blog_posts.status = \"published\" AND blog_posts.published_at < ? AND blog_posts.blog_blog_id=? AND content_tags.name = ?",Time.now,self.id,cat],
                            :per_page => items_per_page)
  end

  def paginate_posts_by_month(page,month,items_per_page)
    begin
      if month =~ /^([a-zA-Z]+)([0-9]+)$/
        tm = Time.parse($1 + " 1 " + $2)
      else
        return nil,[]
      end
    rescue Exception => e
      return nil,[]
    end

    Blog::BlogPost.paginate(page,
			    :include => [ :active_revision, :blog_categories ],
			    :order => 'published_at DESC',
			    :conditions =>   ["blog_posts.status = \"published\" AND blog_posts.published_at < ? AND blog_posts.blog_blog_id=? AND blog_posts.published_at BETWEEN ? AND ?",Time.now,self.id,tm.at_beginning_of_month,tm.at_end_of_month],
			    :per_page => items_per_page)

  end

  def paginate_posts(page,items_per_page)
    Blog::BlogPost.paginate(page,
                            :include => [ :active_revision ], 
                            :order => 'published_at DESC',
                            :conditions => ["blog_posts.status = \"published\" AND blog_posts.published_at < ?  AND blog_blog_id=?",Time.now,self.id],
                            :per_page => items_per_page)          

  end


  def find_post_by_permalink(permalink)
    Blog::BlogPost.find(:first,
                        :include => [ :active_revision ],
                        :order => 'published_at DESC',
                        :conditions => ["blog_posts.status = \"published\" AND blog_blog_id=? AND blog_posts.permalink=?",self.id,permalink])
  end

  def content_type_name
    "Blog"
  end

  def self.filter_options
    ContentFilter.filter_options
  end

  def before_validation_on_create
    self.content_filter = 'markdown_safe' if self.is_user_blog?
  end

  def send_pingbacks(post)
    return unless self.trackback? && post.published?
    post.run_pingbacks(post.active_revision.body_html)
  end
end
