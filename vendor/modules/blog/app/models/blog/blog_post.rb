# Copyright (C) 2009 Pascal Rettig.


class Blog::BlogPost < DomainModel

  validates_uniqueness_of :permalink, :scope => 'blog_blog_id'  

  has_many :blog_post_revisions, :class_name => 'Blog::BlogPostRevision', :dependent => :destroy

  belongs_to :active_revision, :class_name => 'Blog::BlogPostRevision', :foreign_key => 'blog_post_revision_id'
  belongs_to :blog_blog
  
  has_many :blog_posts_categories
  has_many :blog_categories, :through => :blog_posts_categories
  
  validates_presence_of :title

  validates_length_of :permalink, :allow_nil => true, :maximum =>  64
  
  validates_datetime :published_at, :allow_nil => true
   
  has_options :status, [ [ 'Draft','draft'], ['Published','published']] 

  has_many :comments, :as => :target

  include Feedback::PingbackSupport

  cached_content :update => :blog_blog, :identifier => :permalink
  # Add cached content support, but make sure we update the blog cache element
  
  has_content_tags
  
  content_node :container_type => :content_node_container_type,  :container_field => Proc.new { |post| post.content_node_container_id },
  :preview_feature => '/blog/page_feature/blog_post_preview'

  def revision
    @revision ||= self.active_revision ? self.active_revision.clone : Blog::BlogPostRevision.new
  end

  # Special permalink for targeted blogs
  def target_permalink
    "#{self.blog_blog.targeted_blog.url}/#{self.permalink}"
  end

  def content_node_body(language)
    self.active_revision.body_html if self.active_revision
  end

  def content_node_container_type
    self.blog_blog.is_user_blog? ? "Blog::BlogTarget" : 'Blog::BlogBlog'
  end

  def content_node_container_id
    self.blog_blog.is_user_blog? ? 'blog_target_id' : 'blog_blog_id'
  end

  def blog_target_id
    self.blog_blog.blog_target_id
  end

  def comments_count
    return @comments_count if @comments_count
    @comments_count = self.comments.size
    return @comments_count 
  end

  def generate_permalink!
      if permalink.blank? && self.active_revision
        date = self.published_at || Time.now
        permalink_try_partial = date.strftime("%Y-%m-") + self.active_revision.title.downcase.gsub(/[ _]+/,"-").gsub(/[^a-z+0-9\-]/,"")
        idx = 2
        permalink_try = permalink_try_partial[0..60]
        
        while(Blog::BlogPost.find_by_permalink(permalink_try,:conditions => ['id != ?',self.id || 0] ))
          permalink_try = permalink_try_partial + '-' + idx.to_s
          idx += 1
        end
        
        self.permalink = permalink_try
      elsif 
        self.permalink = self.permalink.to_s.gsub(/[^a-z+0-9\-]/,"")
      end
  end

  def category_ids
    self.blog_categories.collect(&:id)
  end

  def set_categories!(category_ids)
    categories_to_delete = []
    categories_to_add = []
    categories_to_keep = []
    category_ids ||= []

    # Find which categories to keep and delete
    # from the existing list
    self.blog_categories.each do |cat|
      if(category_ids.include?(cat.id))
        categories_to_keep << cat.id
      else
        categories_to_delete << cat.id
      end
    end
    
    # Find the categories we need to add from our keep cacluation
    category_ids.each do |cat_id|
      categories_to_add << cat_id unless categories_to_keep.include?(cat_id)
    end

    self.blog_posts_categories.each { |pc| pc.destroy }
    categories_to_add.each do |cat_id|
       self.blog_posts_categories.create(:blog_category_id => cat_id)
    end

    self.blog_categories.reload

  end


  [ :title, :media_file_id, :domain_file_id, :body, :end_user_id, :keywords,
    :author, :embedded_media, :preview_title, :preview ].each do |fld|
    class_eval("def #{fld}; self.revision.#{fld}; end")
    class_eval("def #{fld}=(val); self.revision.#{fld} = val; end")
    end

  [ :domain_file, :preview_content, :end_user,:media_file, :body_content ].each do |fld|
    class_eval("def #{fld}; self.revision.#{fld}; end")
  end

  def image; self.revision.domain_file; end

  def self.get_content_description 
    "Blog Post".t 
  end
  
  def preview
    self.revision.preview.blank? ? self.body_content : self.preview_content
  end

  def self.get_content_options
    self.find(:all,:order => 'title',:include => 'revision').collect do |item|
      [ item.revision.title,item.id ]
    end
  end

  include ActionView::Helpers::TextHelper

  def generate_preview
   self.revision.preview =  truncate(Util::TextFormatter.text_plain_generator(self.revision.body),:length => 140 )
  end

  def self.comment_posted(blog_id)
     
    DataCache.expire_content("Blog")
    DataCache.expire_content("BlogPost")
  end


  def before_save
    self.active_revision.update_attribute(:status,'old') if self.active_revision
    @revision = @revision.clone

    @revision.status = 'active'
    @revision.blog_blog = self.blog_blog
    @revision.blog_post_id = self.id if self.id
    @revision.save

    self.blog_post_revision_id = @revision.id
    self.generate_permalink!
  end

  def after_create
    @revision.update_attribute(:blog_post_id,self.id)
    @revision= nil
  end

  def after_update
    @revision = nil
  end

  def publish_now
    # then unless it's already published, set it to published and update the published_at time
    unless(self.status == 'published' && self.published_at && self.published_at < Time.now) 
        self.status = 'published'
        self.published_at = Time.now
    end
  end
  
  def publish(tm)
    self.status = 'published'
    self.published_at = tm
  end
  
  def make_draft
    self.status = 'draft'  
  end
  
  def published?
    self.status.to_s =='published' && self.published_at && self.published_at < Time.now
  end
  
  
end
