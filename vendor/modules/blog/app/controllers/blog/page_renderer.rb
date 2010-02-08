# Copyright (C) 2009 Pascal Rettig.

class Blog::PageRenderer < ParagraphRenderer

  module_renderer
  
  paragraph :entry_list
  paragraph :entry_detail
  paragraph :categories
  
  features '/blog/page_feature'

  def get_module
    @mod = Blog::PageRenderer.get_module
  end

  def self.get_module
    mod = SiteModule.get_module('blog')
    
    mod.options ||= {}
    mod.options[:field] ||= []
    mod.options[:options] ||= {}
    
    mod
  end



  def entry_list

    page = (params[:page] || 1).to_i
    page = 1 if page < 1

    # .../category/something
    # list_type = category, list_type_identifier = something
    list_connection_type,list_type = page_connection(:type)
    list_connection_detail,list_type_identifier  = page_connection(:identifier)
    
    list_type = list_type.downcase unless list_type.blank?
    unless (['category','tag','archive'].include?(list_type.to_s))
      list_type = nil
    end
    
    if(list_type == 'category')
      set_page_connection(:category,list_type_identifier)
    end

    display_string = "#{paragraph.id}_#{page}_#{list_type}_#{list_type_identifier}"

    options = paragraph_options(:entry_list)
      
      
    if options.blog_id.to_i > 0
      blog_id = options.blog_id
      feature_output = Blog::BlogBlog.cache_fetch(display_string,blog_id)
      blog = Blog::BlogBlog.find_by_id(blog_id) unless feature_output
    elsif editor?
      blog = Blog::BlogBlog.find(:first)
    else
      blog_conn_type,blog_conn_id = page_connection(:blog)

      if blog_conn_type == :container
        blog = Blog::BlogBlog.find_by_target_type_and_target_id(blog_conn_id.class.to_s,blog_conn_id.id)
        feature_output = blog.cache_fetch(display_string) if blog
      elsif blog_conn_type == :blog_id
        blog = Blog::BlogBlog.find_by_id(blog_conn_id)
        feature_output = blog.cache_fetch(display_string) if blog 
      end
    end

    if !feature_output
      return render_paragraph :inline => ''  unless blog

      detail_page =  options.detail_page_url
      if options.include_in_path == 'blog_id'
        detail_page += "/#{blog.id}"
      elsif  options.include_in_path == 'target_id'
        detail_page += "/#{blog.target_id}"
      end
  
      items_per_page = options.items_per_page || 1
      
      entries = []
      pages = {}
  
      case list_type.to_s
      when 'category':
          pages,entries =  blog.paginate_posts_by_category(page,list_type_identifier,items_per_page)
      when 'tag':
          pages,entries = blog.paginate_posts_by_tag(page,list_type_identifier,items_per_page)
      when 'archive':
          pages,entries = blog.paginate_posts_by_month(page,list_type_identifier,items_per_page)
      else
        pages,entries = blog.paginate_posts(page,items_per_page)
      end

      data = { :blog => blog, :entries => entries, :detail_page => detail_page, :list_page => site_node.node_path, :pages => pages }
      
      feature_output = blog_entry_list_feature(data)

      blog.cache_put(display_string,feature_output) unless editor?

    end
    
    require_css('gallery')

    render_paragraph :text => feature_output
  end



  def entry_detail
    options = paragraph_options(:entry_detail)
    
    
    if options.blog_id.to_i > 0
      blog = Blog::BlogBlog.find_by_id(options.blog_id)

      unless blog
        render_paragraph :inline => 'Configure Paragraph' 
        return
      end        
    elsif editor?
      blog = Blog::BlogBlog.find(:first)
    else
      blog_conn_type,blog_conn_id = page_connection(:blog)

      if blog_conn_type == :container
        blog = Blog::BlogBlog.find_by_target_type_and_target_id(blog_conn_id.class.to_s,blog_conn_id.id)
      elsif blog_conn_type == :blog_id
        blog = Blog::BlogBlog.find_by_id(blog_conn_id)
      end
    end

    # Lets get out of here unless we have a blog
    return render_paragraph :text => '' unless blog

    # Put the blog id in the display string just in case we have a two
    # blog posts with the same permalink
    display_string = "#{blog.id}_#{paragraph.id}_#{myself.user_class_id}" 

    if editor?
      entry = blog.blog_posts.find(:first,:conditions => ['blog_posts.status = "published" AND blog_blog_id=? ',blog.id])
      entry_id = entry.id if entry
      entry_title = entry.active_revision.title if entry
    else
      post_connection,post_permalink= page_connection()

      # See if we can completely skip the DB Call
      entry_id,entry_title,feature_output = Blog::BlogPost.cache_fetch(display_string,post_permalink) unless editor?

      if !feature_output && post_connection == :post_permalink && post_permalink
        entry = blog.find_post_by_permalink(post_permalink)
        entry_id = entry.id if entry
        entry_title = entry.active_revision.title if entry && entry.active_revision
      end

    end

    if entry_id
      set_page_connection(:content_id, [ 'Blog::BlogPost',entry_id ] )
      set_page_connection(:post, entry_id  )
    end

    set_title(entry_title)
    set_content_node([ 'Blog::BlogPost',entry_id ])

    if !feature_output
      list_page = options.list_page_url
      if options.include_in_path == 'blog_id'
        list_page += "/#{blog.id}"
      elsif  options.include_in_path == 'target_id'
        list_page += "/#{blog.target_id}"
      end      
    
      data = { :entry => entry, :list_page => list_page, :blog => blog }
      feature_output = blog_entry_detail_feature(data)

      entry.cache_put(display_string, [ entry_id,entry_title,feature_output ], options.blog_post_id.to_i > 0 ? options.blog_post_id :  entry.permalink) unless editor? || !entry
    end
    
    require_css('gallery')

    render_paragraph :text => feature_output
  end
  
  

  
  def categories
    @options = Blog::PageController::CategoriesOptions.new(paragraph.data)
    
    category_connection,selected_category_name = page_connection()
    selected_category_name = nil unless category_connection == 'category'

    display_string = "category_#{paragraph.id}_#{category_connection}_#{selected_category_name}"

    feature_output = Blog::BlogBlog.cache_fetch(display_string,@options.blog_id.to_i) unless editor?

    if !feature_output
    
      categories = Blog::BlogCategory.find(:all,:conditions => { :blog_blog_id => @options.blog_id }, :order => 'name')
      
      data = { :list_url => @options.list_page_url,
        :detail_url => @options.detail_page_url,
        :categories => categories, 
        :selected_category => selected_category_name,
        :blog_id => @options.blog_id }

      feature_output =  blog_categories_feature(data)

      Blog::BlogBlog.cache_put(display_string,feature_output,@options.blog_id.to_i) unless editor?
    end
    
    render_paragraph :text => feature_output
  end
  
end
