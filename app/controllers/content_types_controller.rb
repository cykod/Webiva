# Copyright (C) 2009 Pascal Rettig.


class ContentTypesController < CmsController # :nodoc: all

  
  permit 'editor_content_type'

  cms_admin_paths "content", 'Content Types' => { :action => 'index' }

  include ActiveTable::Controller
  active_table :content_types_table, ContentType,
               [ :check,:content_name,
                 hdr(:static,:list_site_node_id, :label => 'List Page'),
                 hdr(:static,:detail_site_node_id, :label => 'Detail Page'),
                 hdr(:boolean,:search_results, :label => 'Search'),
                 :created_at
                  ]
  
  
  public
  
  def display_content_types_table(display=true)
  
    @tbl = content_types_table_generate params, :order => 'content_types.created_at DESC',:include => [ :detail_site_node, :list_site_node ]
    
    render :partial => 'content_types_table' if display
  end
  
  def index
    cms_page_path ['Content'],'Content Types'
    display_content_types_table(false)
  end
  
  def edit
    @content_type = ContentType.find(params[:path][0])
    cms_page_path [ 'Content','Content Types' ], [ 'Edit %s',nil,@content_type.content_name ]
    
    if request.post? && params[:content_type]
      if params[:commit]
        if @content_type.update_attributes(params[:content_type].slice(:detail_site_node_id,:list_site_node_id,:search_results))
          flash[:notice] = 'Updated Content Type: %s' / h(@content_type.content_name)
          redirect_to :action => 'index'
        end
      else
          redirect_to :action => 'index'
      end
    end
  end

end
