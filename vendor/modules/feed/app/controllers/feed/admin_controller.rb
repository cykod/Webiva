# Copyright (C) 2009 Pascal Rettig.

class Feed::AdminController < ModuleController

  component_info 'Feed', :description => 'Add support for Data Feeds (RSS,XML,JSON) to your website', 
                              :access => :public 
                              
  register_handler :feed, :rss, "Feed::ContentRssHandler"
  register_handler :feed, :rss, "Feed::ContentNodeRssHandler"

  module_for :rss, 'RSS Feed', :description => 'Add a RSS Feed to your site'
  module_for :data_output, 'Data Feed', :description => 'Add a Content Data feed to your site'
  
  register_handler :webiva, :widget, "Feed::GenericFeedWidget"

  layout false

  def rss
    @node = SiteNode.find_by_id_and_module_name(params[:path][0],'/feed/rss')

    @feed_types = [['--Select Feed Type--'.t,'']] + get_handler_options(:feed, :rss)

    rss_options(false)

    if request.post? && params[:options] && @options.valid?
      @page_modifier.update_attribute(:modifier_data,@options.to_h)
      expire_site
      flash.now[:notice] = 'Updated Options'
    end
  end

  def rss_options(display=true)
    @node = SiteNode.find_by_id_and_module_name(params[:path][0],'/feed/rss') unless @node

    @page_modifier = @node.page_modifier

    feed_type = params[:options] ? params[:options][:feed_type] : nil
    if feed_type.nil?
      feed_type = @page_modifier.modifier_data ? @page_modifier.modifier_data[:feed_type] : nil
    end

    options_data = {}
    options_data.merge!(@page_modifier.modifier_data.symbolize_keys) if @page_modifier.modifier_data
    options_data.merge!(params[:options].symbolize_keys) if params[:options]
    @options = self.rss_handler_options_class(feed_type).new(options_data)
    
    render :partial => 'rss_options' if display
  end

  class RssModuleOptions < HashModel
    attributes :feed_type => nil, :feed_title => nil, :timeout => 1
    
    validates_presence_of :feed_type, :feed_title
    integer_options :timeout
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

  protected

  def rss_handler_info(feed_type)
    return nil unless feed_type
    @handler ||= get_handler_info(:feed, :rss, feed_type)
  end

  def rss_handler_options_class(feed_type=nil)
    return RssModuleOptions unless feed_type
    info = self.rss_handler_info(feed_type)
    return RssModuleOptions unless info
    "#{info[:class_name]}::Options".constantize
  end

end
