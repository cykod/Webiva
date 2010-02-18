# Copyright (C) 2009 Pascal Rettig.


class Blog::CategoriesController < ModuleController
  
  permit 'blog_writer'

  component_info 'Blog'

  # need to include 
   include ActiveTable::Controller   
   active_table :category_table,
                Blog::BlogCategory,
                [ hdr(:icon, '', :width=>10),
                  hdr(:string, 'blog_categories.name'),
                  hdr(:static, 'blog_posts_count',:label => 'Entries')
                ]

    def category_table(display=true)

      @blog = Blog::BlogBlog.find(params[:path][0]) unless @blog


      if(request.post? && params[:table_action] && params[:category].is_a?(Hash)) 
        case params[:table_action]
        when 'delete':
          params[:category].each do |entry_id,val|
            Blog::BlogCategory.destroy(entry_id.to_i)
          end
        end
      end

      @active_table_output = category_table_generate(params, :order => 'name DESC', 
                                        :conditions => ['blog_categories.blog_blog_id = ?',@blog.id ],
                                        :include => :blog_posts_categories )

      render :partial => 'category_table' if display
    end

    def index
        @blog = Blog::BlogBlog.find(params[:path][0]) 

       cms_page_info [ ["Content",url_for(:controller => '/content') ], [ "%s",url_for(:controller => '/blog/manage', :action => 'index', :path => @blog.id),@blog.name], 'Manage Categories'], "content"
        
       category_table(false)

      
    end

    def create_category
        @blog = Blog::BlogBlog.find(params[:path][0]) 
  
        cat = @blog.blog_categories.create(:name => params[:name] )
  
        
        category_table(true)
    end
end
