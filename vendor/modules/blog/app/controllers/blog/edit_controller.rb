# Copyright (C) 2009 Pascal Rettig.



class Blog::EditController < ParagraphController

  editor_header 'Blog Paragraphs'
  
  editor_for :list, :name => "User Blog List", :feature => :blog_edit_list,
                       :inputs => { :input => [ [ :container, 'Blog Target', :target] ],
                                    :target_url => [ [:target_url, "Target URL", :path ] ] }

  editor_for :write, :name => "User Blog Write Post", :feature => :blog_edit_write,
                       :inputs => { :target => [ [ :container, 'Blog Target', :target] ],
                                    :post => [ [ :post_permalink, 'Blog Post Permalink', :path ] ],
                                    :target_url => [ [ :target_url, "Target URL", :path ]] }
  


  class ListOptions < HashModel
    attributes :auto_create => true, :blog_name => '%s Blog',:edit_page_id => nil
    
    page_options :edit_page_id
    
    boolean_options :auto_create
  end
  
  class WriteOptions < HashModel
    attributes :list_page_id => nil
    
    page_options :list_page_id
  end

end
