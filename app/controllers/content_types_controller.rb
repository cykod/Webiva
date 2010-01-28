# Copyright (C) 2009 Pascal Rettig.


class ContentTypesController < CmsController # :nodoc: all

  
  permit 'editor_content_type'

  cms_admin_paths "content", 'Configure Content Types' => { :action => 'index' }

  include ActiveTable::Controller
  active_table :content_types_table, ContentType,
               [ :check,
                 "Type",
                 :content_name,
                 hdr(:string,:list_site_node_url, :label => 'List Page'),
                 hdr(:string,:detail_site_node_url, :label => 'Detail Page'),
                 hdr(:boolean,:search_results, :label => 'Search'),
                 hdr(:boolean,:protected_results, :label => 'Protect'),
                 :created_at
                  ]
  
  
  public
  
  def display_content_types_table(display=true)

    active_table_action('content_type') do |act,cids|
      types = ContentType.find(:all,:conditions => {  :id => cids })
      atr = case act
            when 'protect': { :protected_results => true }
            when 'unprotect': { :protected_results => false  }
            when 'search': {  :search_results => true }
            when 'unsearch': {  :search_results => false}
            end
      types.each {  |ct| ct.update_attributes(atr)}
      flash.now[:notice] = "Content Models updated - changes won't take place until the indexer reruns"
    end
  
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

  def rebuild_all_types
    if !request.post?
      redirect_to :action => 'index'
    end

    nodes = SiteNode.find(:all,:include => { :live_revisions => :page_paragraphs })
    paragraph = nodes.each do |node| 
      node.live_revisions.each do |rev| 
        rev.page_paragraphs.map { |para| para.link_canonical_type!(true) }
      end
    end
    flash[:notice] = 'Rebuilt all types'
    redirect_to :action => 'index'
  end

end
