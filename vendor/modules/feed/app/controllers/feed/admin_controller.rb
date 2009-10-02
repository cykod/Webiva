# Copyright (C) 2009 Pascal Rettig.

class Feed::AdminController < ModuleController

  component_info 'Feed', :description => 'Add support for Data Feeds (RSS,XML,JSON) to your website', 
                              :access => :public 
                              
  register_handler :feed, :rss, "Feed::ContentRssHandler"

  module_for :rss, 'RSS Feed', :description => 'Add a RSS Feed to your site'
  module_for :data_output, 'Data Feed', :description => 'Add a Content Data feed to your site'
  
  layout false

  def rss
      @node = SiteNode.find_by_id_and_module_name(params[:path][0],'/feed/rss')
  
      handlers = get_handler_info(:feed,:rss) || []
      
      @feed_types = [['--Select Feed Type--'.t,'']] +  handlers.collect do |handler|
        [ handler[:name], handler[:identifier] ]
      end
      feed_ids(false)
      
      if request.post? && params[:options] && @options.valid?
        @page_modifier.update_attribute(:modifier_data,@options.to_h)
        expire_site
        flash.now[:notice] = 'Updated Options'
      end
  end
  
  def feed_ids(display=true)
    @node = SiteNode.find_by_id_and_module_name(params[:path][0],'/feed/rss') unless @node

    @page_modifier = @node.page_modifier

    @options = RssModuleOptions.new(params[:options] || @page_modifier.modifier_data || {})
    
    if @options.feed_type && (@handler = get_handler_info(:feed,:rss,@options.feed_type))
      @feed_ids = [['--Select Feed--'.t,'']] + @handler[:class].get_feed_options
    end
    
    render :partial => 'feed_ids' if display
  end
  
  class RssModuleOptions < HashModel
    default_options :feed_type => nil, :feed_identifier => nil, :feed_title => nil
    
    validates_presence_of :feed_type, :feed_identifier, :feed_title
  end


  def data_output
      
    @node = SiteNode.find_by_id_and_module_name(params[:path][0],'/feed/data_output') unless @node

    @page_modifier = @node.page_modifier

    @options = DataOutputModuleOptions.new(params[:options] || @page_modifier.modifier_data || {})
    
    if request.post? && params[:options] && @options.valid?
      @page_modifier.update_attribute(:modifier_data,@options.to_h)
      expire_site
      flash.now[:notice] = 'Updated Options'
     end
    

      @data_publications = [['--Select Data Publication--',nil]] + ContentPublication.find_select_options(:all,:conditions => { :publication_type => 'data' })
      
      if @options.data_publication_id.to_i > 0
        @pub = ContentPublication.find_by_id(@options.data_publication_id)
        @site_features = [['--Use Default Site Feature--',nil]] + SiteFeature.find_select_options(:all,:conditions => ['feature_type = ?',@pub.feature_name]) if @pub
      end
      

        
  end
  
  class DataOutputModuleOptions < HashModel
    default_options :data_publication_id => nil, :site_feature_id => nil
    
    integer_options :data_publication_id, :site_feature_id
    
    validates_presence_of :data_publication_id
  end
end
