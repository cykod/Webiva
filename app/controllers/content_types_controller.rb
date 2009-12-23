# Copyright (C) 2009 Pascal Rettig.


class ContentTypesController < CmsController

  
  permit 'editor_content_type'

  cms_admin_paths "content", 'Configure Content Types' => { :action => 'index' }

  include ActiveTable::Controller
  active_table :content_types_table, ContentType,
               [ :check,:content_name,
                 hdr(:string,:list_site_node_url, :label => 'List Page'),
                 hdr(:string,:detail_site_node_url, :label => 'Detail Page'),
                 hdr(:boolean,:search_results, :label => 'Search'),
                 :created_at
                  ]
  
  
  public
  
  def display_content_types_table(display=true)
  
    @tbl = content_types_table_generate params, :order => 'content_types.created_at DESC'
    
    render :partial => 'content_types_table' if display
  end
  
  def index
    cms_page_path ['Content'],'Configure Content Types'
    display_content_types_table(false)
  end
  
  def edit
    @content_type = ContentType.find(params[:path][0])
    cms_page_path [ 'Content','Configure Content Types' ], [ 'Edit %s',nil,@content_type.content_name ]
    
    if request.post? && params[:content_type]
      if params[:commit]
        if @content_type.update_attributes(params[:content_type].slice(:detail_site_node_url,:list_site_node_url,:search_results))
          flash[:notice] = 'Updated Content Type: %s' / h(@content_type.content_name)
          redirect_to :action => 'index'
        end
      else
          redirect_to :action => 'index'
      end
    end
  end

end
