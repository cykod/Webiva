# Copyright (C) 2009 Pascal Rettig.

class Blog::PageController < ParagraphController
  
  editor_header "Blog Paragraphs"
  editor_for :entry_list, :name => 'Blog Entry List',  :features => ['blog_entry_list'],
                       :inputs => { :type => [ [ :list_type, 'List Type (Category,Tags,Archive)', :path ] ],
                                    :identifier => [ [ :list_type_identifier, 'Type Identifier - Category, Tag, or Month name', :path ] ],
                                    :blog => [[ :container, 'Blog Target', :target], [:blog_id,'Blog ID',:path ]]
                                  },
                       :output => [ [:category, 'Selected Category', :blog_category_id ]]

  
  editor_for :entry_detail, :name => 'Blog Entry Detail', :features => ['blog_entry_detail'],
                       :inputs => { :input => [ [ :post_permalink, 'Blog Post Permalink', :path ],
                                                [ :post, 'Blog Post', :post_id ] ],
                                    :blog => [ [ :container, 'Blog Target', :target] ]           
                                  },
                          :outputs => [ [ :content_id, 'Content Identifier', :content ],
                                        [ :post, 'Blog Post', :post_id ] ]

  editor_for :categories, :name => 'Blog Categories' ,:features => ['blog_categories'],
                        :inputs => [ [ :category, 'Selected Category', :blog_category_id ]]
                                    
  def entry_list
      
    @blogs = [['---Use Page Connection---'.t,'']] + Blog::BlogBlog.find_select_options(:all,:order=>'name')

    @options = EntryListOptions.new(params[:entry_list] || @paragraph.data)
      
    return if handle_module_paragraph_update(@options)

    if @options.blog_id.to_i > 0
      @categories = [['--All Categories--'.t,nil]] + Blog::BlogCategory.select_options(:conditions => { :blog_blog_id => @options.blog_id })
    else
      @categories = [['--All Categories--'.t,nil]] + Blog::BlogCategory.find(:all,:include => :blog_blog).map { |elm| ["#{elm.blog_blog.name} - #{elm.name}",elm.id ] }
    end
    @per_page = (1..50).to_a
    @pages = SiteNode.page_options()
  end

  
 
  class EntryListOptions < HashModel
      default_options :blog_id => nil, :items_per_page => 10,:detail_page => nil,:category_id => nil,:include_in_path => nil
      
      integer_options :blog_id, :items_per_page, :detail_page,:category_id
  end
    

  def entry_detail
    @blogs = [['---Use Page Connection---'.t,'']] + Blog::BlogBlog.find_select_options(:all,:order=>'name')
    @options = EntryDetailOptions.new(params[:entry_detail] || @paragraph.data)
    return if handle_module_paragraph_update(@options)
  end

  class EntryDetailOptions < HashModel
      default_options :blog_id => nil, :list_page_id => nil,:include_in_path => nil
      
      integer_options :blog_id, :list_page_id

      canonical_paragraph "Blog::BlogBlog", :blog_id, :list_page_id => :list_page_id
  end
  
  def categories
    @blogs =  [['---Select Blog---'.t,'']] + Blog::BlogBlog.find_select_options(:all,:order=>'name')
    @options = CategoriesOptions.new(params[:categories] || @paragraph.data)
    return if handle_module_paragraph_update(@options)
    
    @pages = [['--Select a page--'.t,nil]] + SiteNode.page_options
  end
  

  class CategoriesOptions < HashModel
      default_options :blog_id => nil, :list_page_id => nil, :detail_page_id => nil
      
      integer_options :blog_id, :list_page_id, :detail_page_id

      validates_presence_of :blog_id, :list_page_id, :detail_page_id
  end
end
