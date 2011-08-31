# Copyright (C) 2009 Pascal Rettig.

class Blog::PageRenderer < ParagraphRenderer

  module_renderer
  
  paragraph :entry_list
  paragraph :entry_detail
  paragraph :categories
  paragraph :targeted_entry_detail
  
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
    @options = paragraph_options(:entry_list)

    page = (params[:page] || 1).to_i
    page = 1 if page < 1

    # .../category/something
    # list_type = category, list_type_identifier = something
    list_connection_type,list_type = page_connection(:type)

    list_connection_detail,list_type_identifier  = page_connection(:identifier)

    if list_type == 'category'
      category_filter  = list_type_identifier
    elsif list_type == 'tag'
      tag_filter = list_type_identifier
    end

    list_connection_detail, category_filter = page_connection(:category) if page_connection(:category)
    tag_type, tag_filter =  page_connection(:tag) if page_connection(:tag)

    if list_type && ! editor?
      list_type = list_type.downcase unless list_type.blank?
      unless (['category','tag','archive'].include?(list_type.to_s))
        raise SiteNodeEngine::MissingPageException.new(site_node, language) if list_type_identifier && site_node.id == @options.detail_page_id
        set_page_connection(:category, nil)
        return render_paragraph :text => ''
      end
    end

    if category_filter
      category_filter = category_filter.to_s.gsub("+"," ")
      set_page_connection(:category, category_filter)
    else
      set_page_connection(:category, nil)
    end

    type_hash = DomainModel.hexdigest("#{list_type}_#{list_type_identifier}_#{category_filter}_#{tag_filter}")
    display_string = "#{page}_#{type_hash}"

    result = renderer_cache(Blog::BlogPost, display_string) do |cache|
      if !@options.category.blank? && @options.limit_by == "category"
        category_filter = @options.category.split(",").map(&:strip).reject(&:blank?)
      elsif !@options.category.blank? && @options.limit_by == "tag"
        tag_filter = @options.category.split(",").map(&:strip).reject(&:blank?)
      end

      blog = get_blog
      return render_paragraph :text => (@options.blog_id.to_i > 0 ? '[Configure paragraph]' : '') unless blog || @options.blog_id == -1

      detail_page =  get_detail_page
      items_per_page = (@options.items_per_page || 1).to_i
      
      entries = []
      pages = {}
  
      if blog
        if list_type.to_s == 'archive'
          pages,entries = blog.paginate_posts_by_month(page,list_type_identifier,items_per_page,:large => @options.skip_total)
        else
          pages,entries = blog.paginate_posts(@options.skip_page ? 1 : page,items_per_page,:large => @options.skip_total, :category_filter => category_filter, :tag_filter => tag_filter, :order => @options.order == 'date' ? 'blog_posts.published_at DESC' : 'blog_posts.rating DESC')
        end
      else
        pages,entries = Blog::BlogPost.paginate_published(page,items_per_page,@options.blog_ids,:large => @options.skip_total)
      end

      cache[:title] = blog.name if blog
      cache[:output] = blog_entry_list_feature(:blog => blog,
					       :entries => entries,
					       :detail_page => detail_page,
					       :list_page => @options.list_page_url || site_node.node_path,
					       :pages => pages,
					       :type => list_type,
					       :identifier => list_type_identifier)
    end

    set_title(result.title) if result.title 
    require_css('gallery')
    render_paragraph :text => result.output
  end

  def entry_detail
    @options = paragraph_options(:entry_detail)

    blog = get_blog
    return render_paragraph :text => (@options.blog_id.to_i > 0 ? '[Configure paragraph]' : '') unless blog

    conn_type, conn_id = page_connection()
    display_string = "#{conn_type}_#{conn_id}_#{myself.user_class_id}"

    result = renderer_cache(blog, display_string) do |cache|
      entry = nil
      if editor?
        entry = blog.blog_posts.find(:first,:conditions => ['blog_posts.status = "published" AND blog_blog_id=? ',blog.id])
      elsif conn_type == :post_permalink
        entry = blog.find_post_by_permalink(conn_id)
      end

      cache[:content_node_id] = entry.content_node.id if entry && entry.content_node
      cache[:output] = blog_entry_detail_feature(:entry => entry,
                                                 :list_page => get_list_page(blog),
                                                 :blog => blog)
      cache[:title] = entry ? entry.title : ''
      cache[:keywords] = (entry && !entry.keywords.blank?) ? entry.keywords : nil
      cache[:entry_id] = entry ? entry.id : nil
      cache[:comments_ok] = entry ? ! entry.disallow_comments : true
    end

    if result.entry_id
      set_page_connection(:content_id, ['Blog::BlogPost',result.entry_id] )
      set_page_connection(:content_node_id, result.content_node_id )
      set_page_connection(:post, result.entry_id )
      set_page_connection(:comments_ok, result.comments_ok)
      set_title(result.title)
      set_content_node(result.content_node_id)
      html_include('meta_keywords',result.keywords) if result.keywords 
    else
      return render_paragraph :text => '' if (['', 'category','tag','archive'].include?(conn_id.to_s.downcase)) && site_node.id == @options.list_page_id
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless editor?
    end

    require_css('gallery')

    render_paragraph :text => result.output
  end

  def targeted_entry_detail
    @options = paragraph_options(:targeted_entry_detail)
    return render_paragraph :text => "[Configure Paragraph]" unless @options.blog_target_id > 0

    blog = get_blog

    return render_paragraph :text => '' unless blog

    conn_type, conn_id = page_connection()
    display_string = "#{conn_type}_#{conn_id}_#{myself.user_class_id}"

    result = renderer_cache(blog, display_string) do |cache|
      entry = nil
      if editor?
        entry = blog.blog_posts.find(:first,:conditions => ['blog_posts.status = "published" AND blog_blog_id=? ',blog.id])
      elsif conn_type == :post_permalink
        entry = blog.find_post_by_permalink(conn_id) if conn_id
      end

      cache[:output] = blog_entry_detail_feature(:entry => entry,
                                                 :list_page => get_list_page(blog),
                                                 :detail_page => site_node.node_path,
                                                 :blog => blog)
      cache[:title] = entry ? entry.title : ''
      cache[:entry_id] = entry ? entry.id : nil
    end

    if result.entry_id
      set_page_connection(:content_id, ['Blog::BlogPost',result.entry_id] )
      set_page_connection(:post, result.entry_id )
      set_title(result.title)
      set_content_node(['Blog::BlogPost', result.entry_id])
    else
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless editor?
    end

    require_css('gallery')

    render_paragraph :text => result.output
  end






  def categories
    @options = paragraph_options(:categories)
    
    category_connection,selected_category_name = page_connection()
    selected_category_name = nil unless category_connection == 'category'

    display_string = "#{category_connection}_#{selected_category_name}"

    result = renderer_cache(Blog::BlogBlog, display_string) do |cache|
      @categories = Blog::BlogCategory.find(:all, :conditions => {:blog_blog_id => @options.blog_id}, :order => 'name')
      
      cache[:output] =  blog_categories_feature(:list_page => @options.list_page_url,
						:detail_page => @options.detail_page_url,
						:categories => @categories, 
						:selected_category => selected_category_name,
						:blog_id => @options.blog_id
						)
    end
    
    render_paragraph :text => result.output
  end

  protected

  def get_blog
    if @options.blog_id.to_i < 0
      nil
    elsif @options.blog_id.to_i > 0
      Blog::BlogBlog.find_by_id(@options.blog_id.to_i)
    elsif editor?
      blog = Blog::BlogBlog.find(:first)
    else
      conn_type, conn_id = page_connection(:blog)
      if conn_type == :container
        Blog::BlogBlog.find_by_target_type_and_target_id(conn_id.class.to_s, conn_id.id,:conditions => {:blog_target_id => @options.blog_target_id})
      elsif conn_type == :blog_id
        Blog::BlogBlog.find_by_id(conn_id.to_i)
      end
    end
  end

  def get_detail_page
    detail_page =  @options.detail_page_url
    return nil unless detail_page
    if @options.include_in_path == 'blog_id'
      detail_page += "/#{blog.id}"
    elsif  @options.include_in_path == 'target_id'
      detail_page += "/#{blog.target_id}"
    end
    SiteNode.link detail_page
  end

  def get_list_page(blog)
    list_page =  @options.list_page_url
    return nil unless list_page
    if blog
      if @options.include_in_path == 'blog_id'
        list_page += "/#{blog.id}"
      elsif  @options.include_in_path == 'target_id'
        list_page += "/#{blog.target_id}"
      end
    end
    SiteNode.link list_page
  end
end
