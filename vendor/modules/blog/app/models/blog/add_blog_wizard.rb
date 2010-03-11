

class Blog::AddBlogWizard < HashModel

  attributes :blog_id => nil, 
  :add_to_id=>nil,
  :add_to_subpage => nil,
  :add_to_existing => nil,
  :detail_page_url => 'view',
  :opts => []

  
  validates_format_of :add_to_subpage, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url', :allow_blank => true
  validates_format_of :detail_page_url, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url'
  validates_presence_of :add_to_id

  validates_presence_of :blog_id
  validates_presence_of :detail_page_url

  def validate
    if self.add_to_existing.blank? && self.add_to_subpage.blank?
      self.errors.add(:add_to," must have a subpage selected or add\n to existing must be checked")
    end
  end

  def add_to_site!
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
    

  end
end
