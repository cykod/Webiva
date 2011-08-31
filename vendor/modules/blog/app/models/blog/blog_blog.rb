# Copyright (C) 2009 Pascal Rettig.


class Blog::BlogBlog < DomainModel

  validates_presence_of :name
  validates_presence_of :content_filter

  belongs_to :target, :polymorphic => true

  belongs_to :blog_target

  belongs_to :content_model
  belongs_to :content_publication

  has_many :blog_posts, :dependent => :destroy, :include => :active_revision
  has_many :blog_categories, :class_name => 'Blog::BlogCategory', :dependent => :destroy, :order => 'blog_categories.name'

  serialize :options_data

  cached_content # Add cached content support 

  attr_accessor :add_to_site

  alias_method :targeted_blog, :target

  include SiteAuthorizationEngine::Target
  access_control :edit_permission
  
  serialize :options
  
  content_node_type :blog, "Blog::BlogPost", :content_name => :name,:title_field => :title, :url_field => :permalink, :except => Proc.new { |blg| blg.is_user_blog? }
  
  def self.create_user_blog(name,target)
    self.create(:name => name, :target => target, :is_user_blog => true)
  end

  def content_admin_url(blog_entry_id)
    {  :controller => '/blog/manage', :action => 'post', :path => [ self.id, blog_entry_id ],
       :title => 'Edit Blog Entry'.t}
  end

  def content_categories
    self.blog_categories
  end

  def content_category_nodes(category_id)
    ContentNode.all :conditions => {:node_type => 'Blog::BlogPost', :content_type_id => self.content_type.id, 'blog_posts_categories.blog_category_id' => category_id}, :joins => 'JOIN blog_posts_categories ON blog_post_id = node_id'
  end

  def paginate_posts_by_date(page,date_name,items_per_page,options = {})
    today = Time.now.at_midnight; end_time = Time.now
    case date_name.downcase
    when 'day':   start_time = today
    when 'week':  start_time = today - 7.days;
    when 'month': start_time = today.at_beginning_of_month
    when 'last_month': start_time = (today - 1.months).at_beginning_of_month; end_time = start_time.at_end_of_month
    when 'six_months': start_time = today - 6.months
    else return nil,[]
    end

    Blog::BlogPost.paginate(page,
                            { :include => [ :active_revision ],
                            :joins => [ :blog_posts_categories ],
                            :order => 'published_at DESC',
                            :conditions => [ "blog_posts.status = \"published\" AND blog_posts.blog_blog_id=? and published_at BETWEEN ? and ?",self.id,start_time,end_time],
                            :per_page => items_per_page }.merge(options))
  end                       


  def paginate_posts_by_category(page,cat,items_per_page,options = {})
    cat = [ cat] unless cat.is_a?(Array)

    category_ids = self.blog_categories.find(:all,:conditions => { :name => cat },:select=>'id').map(&:id)

    category_ids = [ 0] if category_ids.length == 0

    Blog::BlogPost.paginate(page,
                            { :include => [ :active_revision ],
                            :joins => [ :blog_posts_categories ],
                            :order => 'published_at DESC',
                            :conditions => [ "blog_posts.status = \"published\" AND blog_posts.published_at < ? AND blog_posts.blog_blog_id=? AND blog_posts_categories.blog_category_id in (?)",Time.now,self.id, category_ids],
                            :per_page => items_per_page }.merge(options))
  end                       


  def paginate_posts_by_tag(page,tag,items_per_page,options = {})

    tag = [ tag ] unless tag.is_a?(Array)

    tag_ids = ContentTag.find(:all,:conditions => { :name => tag },:select => 'id').map(&:id)
    tag_ids = [ 0 ] if tag_ids.length == 0

    Blog::BlogPost.paginate(page,
                            { :include => [ :active_revision ],
                            :joins => [ :content_tag_tags ],
                            :order => 'published_at DESC',
                            :conditions => ["blog_posts.status = \"published\" AND blog_posts.published_at < ? AND blog_posts.blog_blog_id=? AND content_tag_tags.content_tag_id in (?)",Time.now,self.id,tag_ids],
                            :per_page => items_per_page}.merge(options))
  end

  def paginate_posts_by_month(page,month,items_per_page,options = {})
    begin
      if month =~ /^([a-zA-Z]+)([0-9]+)$/
        tm = Time.parse($1 + " 1 " + $2)
      else
        return paginate_posts_by_date(page,month,items_per_page,options)
      end
    rescue Exception => e
      return nil,[]
    end

    Blog::BlogPost.paginate(page, {
			    :include => [ :active_revision, :blog_categories ],
			    :order => 'published_at DESC',
			    :conditions =>   ["blog_posts.status = \"published\" AND blog_posts.published_at < ? AND blog_posts.blog_blog_id=? AND blog_posts.published_at BETWEEN ? AND ?",Time.now,self.id,tm.at_beginning_of_month,tm.at_end_of_month],
			    :per_page => items_per_page }.merge(options))

  end

  def paginate_posts(page,items_per_page,options = {})
    opts = options.symbolize_keys

    post_options = {  :include => [ :active_revision ], 
                      :order => 'published_at DESC',
                      :conditions => ["blog_posts.status = \"published\" AND blog_posts.published_at < ?  AND blog_blog_id=?",Time.now,self.id],
                      :per_page => items_per_page }

    if tag = opts.delete(:tag_filter)
      tag = [ tag ] unless tag.is_a?(Array)

      tag_ids = ContentTag.find(:all,:conditions => { :name => tag },:select => 'id').map(&:id)
      tag_ids = [ 0 ] if tag_ids.length == 0

      post_options[:include] << :content_tag_tags
      post_options[:conditions][0] += "  AND content_tag_tags.content_tag_id in (?)"
      post_options[:conditions] << tag_ids
    end

    if cat = opts.delete(:category_filter)
      cat = [ cat] unless cat.is_a?(Array)
      category_ids = self.blog_categories.find(:all,:conditions => { :name => cat },:select=>'id').map(&:id)

      category_ids = [ 0] if category_ids.length == 0
     post_options[:include] << :blog_posts_categories
      post_options[:conditions][0] += "  AND blog_posts_categories.blog_category_id in (?)"
      post_options[:conditions] << category_ids
    end

    Blog::BlogPost.paginate(page,post_options.merge(opts))          

  end


  def find_post_by_permalink(permalink)
    Blog::BlogPost.find(:first,
                        :include => [ :active_revision ],
                        :order => 'published_at DESC',
                        :conditions => ["blog_posts.status in('published','preview') AND blog_blog_id=? AND blog_posts.permalink=?",self.id,permalink])
  end

  def content_type_name
    "Blog"
  end

  def self.filter_options
    ContentFilter.filter_options
  end

  def before_save
    self.content_publication_id = nil if self.content_model.nil? || self.content_publication.nil? || self.content_model.id != self.content_publication.content_model_id
  end

  def before_validation_on_create
    if self.is_user_blog?
      self.content_filter = 'safe_html' if self.is_user_blog?
      self.blog_target_id = Blog::BlogTarget.fetch_for_target(self.target)
    end
  end

  def send_pingbacks(post)
    return unless self.trackback? && post.published?
    post.run_pingbacks(post.active_revision.body_html)
  end

  def content_detail_link_url(path,obj)
    if self.blog_options.category_override
      "#{path}/#{obj.first_category.permalink}/#{obj.permalink}"
    else 
      "#{path}/#{obj.permalink}"
    end
  end

  def blog_options(val=nil)
    @options_cache = nil if val
    @options_cache ||= BlogOptions.new(val || self.options_data)
    @options_cache
  end

  def blog_options=(val)
    self.options_data = blog_options(val).to_hash
  end

  class BlogOptions < HashModel
    attributes :category_override => false
    boolean_options :category_override
  end

  @@import_fields  = %w(title permalink author published_at preview body embedded_media).map(&:to_sym)

  def import_file(domain_file,user)
     filename = domain_file.filename
     reader = CSV.open(filename,"r",',')
     file_fields = reader.shift
     reader.each do |row|
       args = {}
       @@import_fields.each_with_index { |fld,idx| args[fld] = row[idx] }

       post = self.blog_posts.find_by_permalink(args[:permalink]) if !args[:permalink].blank?

       args[:author] = user.name if args[:author].blank?
       post ||= self.blog_posts.build

       post.attributes = args
       post.publish(args[:published_at])  if !args[:published_at].blank?
       post.save
     end
  end

end
