

class Blog::AddBlogWizard < WizardModel

  def self.structure_wizard_handler_info
    { :name => "Add a Blog to your Site",
      :description => 'This wizard will add an existing blog to a url on your site.',
      :permit => "blog_config",
      :url => self.wizard_url
    }
  end

  attributes :blog_id => nil, 
  :add_to_id=>nil,
  :add_to_subpage => 'blog',
  :add_to_existing => nil,
  :detail_page_url => 'view',
  :opts => [],
  :number_of_dummy_posts => 3

  
  validates_format_of :add_to_subpage, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url', :allow_blank => true
  validates_format_of :detail_page_url, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url'
  validates_presence_of :add_to_id

  validates_presence_of :blog_id
  validates_presence_of :detail_page_url

  integer_options :number_of_dummy_posts

  options_form(
               fld(:blog_id, :select, :options => :blog_select_options, :label => 'Blog to Add'),
               fld(:add_to, :add_page_selector),
               fld(:detail_page_url, :text_field, :label => "Detail Page", :size => 10),
               fld(:opts, :check_boxes,
                   :options => [['Add a comments paragraph','comments'],
                                ['Add Categories to list page','categories']],
                   :label => 'Options', :separator => '<br/>'
                   ),
               fld(:number_of_dummy_posts, :text_field, :description => 'Number of dummy posts to create if blog has no posts', :label => 'Dummy posts')
               )

  def blog_select_options
    Blog::BlogBlog.select_options_with_nil('Blog')
  end

  def validate
    nd = SiteNode.find_by_id(self.add_to_id)
    if (self.add_to_existing.blank? && self.add_to_subpage.blank?)
      self.errors.add(:add_to," must have a subpage selected\nand add to existing must be checked")
    end
    if ( !self.add_to_existing.blank? && ( !nd || nd.node_type == 'R'))
      self.errors.add(:add_to,"you cannot add the blog to the site root, please pick a page\nor uncheck 'Add to existing page'")
    end
  end

  def can_run_wizard?
    Blog::BlogBlog.count > 0
  end

  def setup_url
    {:controller => '/blog/admin', :action => 'create', :version => self.site_version_id}
  end

  def set_defaults(params)
    self.blog_id = params[:blog_id].to_i if params[:blog_id]
  end

  def run_wizard
    nd = SiteNode.find(self.add_to_id)

    if self.add_to_existing.blank?
      nd = nd.add_subpage(self.add_to_subpage)
    end

    sub = nd.add_subpage(self.detail_page_url)
    sub.save
    
    list_revision = nd.page_revisions[0]
    detail_revision = sub.page_revisions[0]

    list_para = list_revision.add_paragraph('/blog/page','entry_list',
                                { 
                                  :detail_page => sub.id,
                                  :blog_id => self.blog_id
                                }
                                )
    list_para.add_page_input(:type,:page_arg_0,:list_type)
    list_para.add_page_input(:identifier,:page_arg_1,:list_type_identifier)
    list_para.save

    detail_para = detail_revision.add_paragraph('/blog/page','entry_detail',
                              { 
                                  :list_page_id => nd.id,
                                  :blog_id => self.blog_id
                              }
                              )

    detail_para.add_page_input(:input,:page_arg_0,:post_permalink)
    detail_para.save

    if self.opts.include?('comments')
      
      comments_paragraph = detail_revision.add_paragraph('/feedback/comments','comments',
                              { 
                                      :show => -1,
                                      :allowed_to_post => 'all',
                                      :linked_to_type => 'connection',
                                      :captcha => false,
                                      :order => 'newest'
                              }
                              )

      comments_paragraph.save
      comments_paragraph.add_paragraph_input!(:input,detail_para,:content_id,:content_identifier)
    end

    if self.opts.include?('categories')
        cat_para = list_revision.add_paragraph('/blog/page','categories',
                                { 
                                  :detail_page => sub.id,
                                  :blog_id => self.blog_id,
                                  :list_page_id => nd.id
                                },
                                :zone => 3
                                )
      cat_para.save
      cat_para.add_paragraph_input!(:input,list_para,:category,:category)
    end

    detail_revision.make_real
    list_revision.make_real

    if self.blog.blog_posts.count == 0 && self.number_of_dummy_posts > 0
      categories = [self.create_dummy_category, self.create_dummy_category]
      (1..self.number_of_dummy_posts).each do |idx|
        self.create_dummy_post(categories[rand(categories.size)])
      end
    end
  end

  def blog
    @blog ||= Blog::BlogBlog.find self.blog_id
  end

  def create_dummy_category
    self.blog.blog_categories.create :name => DummyText.words(1).split(' ')[0..1].join(' ')
  end

  def create_dummy_post(cat)
    post = self.blog.blog_posts.create :body => DummyText.paragraphs(1+rand(3), :max => 1), :author => DummyText.words(1).split(' ')[0..1].join(' '), :title => DummyText.words(1), :status => 'published', :published_at => Time.now
    Blog::BlogPostsCategory.create :blog_post_id => post.id, :blog_category_id => cat.id
    post
  end
end
