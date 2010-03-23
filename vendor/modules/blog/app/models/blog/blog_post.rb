# Copyright (C) 2009 Pascal Rettig.


class Blog::BlogPost < DomainModel

  validates_uniqueness_of :permalink, :scope => 'blog_blog_id'  

  has_many :blog_post_revisions, :class_name => 'Blog::BlogPostRevision', :dependent => :destroy

  belongs_to :active_revision, :class_name => 'Blog::BlogPostRevision', :foreign_key => 'blog_post_revision_id'
  belongs_to :blog_blog
  
  has_many :blog_posts_categories
  has_many :blog_categories, :through => :blog_posts_categories
  

  validates_length_of :permalink, :allow_nil => true, :maximum =>  64
  
  validates_datetime :published_at, :allow_nil => true
   
  has_options :status, [ [ 'Draft','draft'], ['Published','published']] 

  has_many :comments, :as => :target

  include Feedback::PingbackSupport

  cached_content :update => :blog_blog, :identifier => :permalink
  # Add cached content support, but make sure we update the blog cache element
  
  has_content_tags
  
  content_node :container_type => 'Blog::BlogBlog', :container_field => 'blog_blog_id',
  :preview_feature => '/blog/page_feature/blog_post_preview'

  def content_node_body(language)
    self.active_revision.body_html if self.active_revision
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
  
  def preview
    self.active_revision.preview.blank? ? self.active_revision.body : self.active_revision.preview
  end

  def title
    self.active_revision.title
  end 

  def image
    self.active_revision.domain_file
  end
  
  def media_file
    self.active_revision.media_file
  end

  def self.get_content_description 
    "Blog Post".t 
  end

  def self.get_content_options
    self.find(:all,:order => 'title',:include => 'active_revision').collect do |item|
      [ item.active_revision.title,item.id ]
    end
  end

  def self.comment_posted(blog_id)
     
    DataCache.expire_content("Blog")
    DataCache.expire_content("BlogPost")
  end
  
  def save_revision!(revision)
    self.reload(:lock => true) if self.id
    Blog::BlogPostRevision.transaction do
      self.active_revision.update_attribute(:status,'old') if self.id && self.active_revision
      
      self.save if !self.id

      revision.status = 'active'
      revision.blog_post = self
      
      revision.save

      # make the new revision the active revision
      self.active_revision = revision
      self.generate_permalink!
      self.save
    end
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
