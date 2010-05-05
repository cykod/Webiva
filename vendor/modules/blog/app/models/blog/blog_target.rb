
class Blog::BlogTarget < DomainModel

  has_many :blog_blogs 

  content_node_type :blog, "Blog::BlogPost", :content_name => :name,:title_field => :title, :url_field => :target_permalink 

  def content_admin_url(blog_entry_id)
    post = Blog::BlogPost.find_by_id(blog_entry_id)
    if post
      {  :controller => '/blog/manage', :action => 'post', :path => [ post.blog_blog_id, blog_entry_id ],
        :title => 'Edit Blog Entry'.t}
    else
      {}
    end
  end

  def content_type_name
    "Target Blog"
  end

  def name
    self.target_type.to_s.titleize + " Blogs"
  end

  def self.fetch_for_target(target)

    if target.respond_to?(:content_node) && target.content_node
      args = { :content_type_id => target.content_node.content_type_id,
               :target_type => target.class.to_s }
    else
      args = { :target_type => target.class.to_s }
    end
    self.find(:first,:conditions => args) || self.create(args)      
  end

  
end
