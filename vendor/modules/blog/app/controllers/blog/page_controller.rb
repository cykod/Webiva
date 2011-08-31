# Copyright (C) 2009 Pascal Rettig.

class Blog::PageController < ParagraphController
  
  editor_header "Blog Paragraphs"

  editor_for :entry_list, :name => 'Blog Entry List', :features => ['blog_entry_list'],
                       :inputs => { :type =>       [[:list_type, 'List Type (Category,Tags,Archive)', :path]],
                                    :identifier => [[:list_type_identifier, 'Type Identifier - Category, Tag, or Month name', :path]],
                                    :category => [[:category, 'Category Name', :path ]],
                                    :tag => [[:tag, "Tag Name", :path ]],
                                    :blog =>       [[:container, 'Blog Target', :target],
                                                    [:blog_id,'Blog ID',:path]]
                                  },
                       :outputs => [[:category, 'Selected Category', :blog_category_id]]

  
  editor_for :entry_detail, :name => 'Blog Entry Detail', :features => ['blog_entry_detail'],
                       :inputs => { :input => [[ :post_permalink, 'Blog Post Permalink', :path ]],
                                    :blog => [[:blog_id,'Blog ID',:path ]]
                                  },
                       :outputs => [[:content_id, 'Content Identifier', :content],
                                    [:comments_ok, 'Allow Commenting', :boolean ],
                                    [:content_node_id, 'Content Node', :content_node_id ],
                                    [:post, 'Blog Post', :post_id ]]
                                  
  editor_for :targeted_entry_detail, :name => "Targeted Blog Entry Detail",  :features => ['blog_entry_detail'],
                      :inputs => { 
                         :input => [[ :post_permalink, 'Blog Post Permalink', :path ]],
                         :blog => [[ :container, 'Blog Target', :target]]
                         },
                        :outputs => [[:content_id, 'Content Identifier', :content],
                                     [:post, 'Blog Post', :post_id ]]




  editor_for :categories, :name => 'Blog Categories' ,:features => ['blog_categories'],
                        :inputs => [[:category, 'Selected Category', :blog_category_id]]
 
  class EntryListOptions < HashModel
    attributes :blog_id => 0, :items_per_page => 10, :detail_page => nil, :list_page_id => nil, :include_in_path => nil,:blog_target_id => nil, :category => nil, :limit_by => 'category', :blog_ids => [], :skip_total => false, :skip_page => false, :order => 'date'

    integer_array_options :blog_ids

    boolean_options :skip_total, :skip_page

    def detail_page_id
      self.detail_page
    end

    integer_options :blog_id, :items_per_page, :detail_page
    page_options :detail_page_id, :list_page_id

    options_form(fld(:blog_id, :select, :options => :blog_options),
		 fld(:detail_page, :page_selector,   :description => 'Leave blank to use canonical content url'),
     fld(:list_page_id, :page_selector,  :description => 'Leave blank to use the current page as the list page'),
   	 fld(:items_per_page, :select, :options => (1..50).to_a),
     fld('Advanced Options',:header),
     fld(:blog_target_id, :select, :options => :blog_target_options, :description => 'Advanced use only'),
     fld(:blog_ids, :ordered_array, :options => :blog_name_options, :label => 'For multiple blogs',:description => 'Leave blank to show all blogs'),
     fld(:order,:select,:options => [['Newest','date'],['Rating','rating']]),
     fld(:limit_by,:radio_buttons,:label => 'Limit to',:options => [[ 'Categories','category'],['Tags','tag']]),
     fld(:category,:text_field,:label => "Limit to",:description => "Comma separated list of categories or tags"),
     fld(:skip_total, :yes_no, :description => "Set to yes for paragraphs without pagination or for blogs\n with a large number (>1000) of posts to speed rendering"),
     fld(:skip_page, :yes_no, :description => "Set to yes to skip looking at the current page number\nuseful for framework paragraphs")
    
		 )

    def blog_target_options; Blog::BlogTarget.select_options_with_nil; end

    def blog_name_options
      Blog::BlogBlog.find_select_options(:all,:order=>'name')
    end

    def blog_options
      [['---Use Page Connection---'.t,'']] + [['Multiple Blogs'.t,-1]] + Blog::BlogBlog.find_select_options(:all,:order=>'name')
    end

    def include_in_path_options
      [["Don't include path in target", nil],
       ["Include Blog ID in detail path", "blog_id"],
       ["Include Target ID in detail path", "target_id"]]
    end
  end
    
  class EntryDetailOptions < HashModel
    attributes :blog_id => 0, :list_page_id => nil, :include_in_path => nil
      
    integer_options :blog_id
    page_options :list_page_id

    options_form(fld(:blog_id, :select, :options => :blog_options),
		 fld(:list_page_id, :page_selector),
		 fld(:include_in_path, :select, :options => :include_in_path_options)
		 )

    canonical_paragraph "Blog::BlogBlog", :blog_id, :list_page_id => :list_page_id

    def blog_options
      [['---Use Page Connection---'.t,'']] + Blog::BlogBlog.find_select_options(:all,:order=>'name')
    end

    def include_in_path_options
      [["Don't include path in target", nil],
       ["Include Blog ID in detail path", "blog_id"],
       ["Include Target ID in detail path", "target_id"]]
    end
  end


  class TargetedEntryDetailOptions < HashModel
    attributes :blog_target_id => 0

    validates_presence_of :blog_target_id
    options_form(fld(:blog_target_id, :select, :options => :blog_target_options))

    def blog_target_options; Blog::BlogTarget.select_options_with_nil; end

    canonical_paragraph "Blog::BlogTarget", :blog_target_id

  end
  
  class CategoriesOptions < HashModel
    attributes :blog_id => nil, :list_page_id => nil, :detail_page_id => nil

    integer_options :blog_id
    page_options :list_page_id, :detail_page_id

    validates_presence_of :blog_id, :list_page_id, :detail_page_id

    options_form(fld(:blog_id, :select, :options => :blog_options),
		 fld(:list_page_id, :page_selector),
		 fld(:detail_page_id, :page_selector)
		 )

    def blog_options
      [['---Select Blog---'.t,'']] + Blog::BlogBlog.find_select_options(:all,:order=>'name')
    end
  end
end
