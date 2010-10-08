# Copyright (C) 2009 Pascal Rettig.

class Editor::AdminController < ModuleController #:nodoc:all
  permit 'editor'
  
  layout nil
  # These modules are always active
  skip_before_filter :validate_module
  
  component_info 'editor', :description => 'Built In Editor Modules', 
                              :access => :public

  
  content_node_type "Static Pages", "SiteNode",  :search => true, :editable => false, :title_field => :name, :url_field => :node_path

  module_for :opensearch, 'OpenSearch', :description => 'Add OpenSearch to your site'
  module_for :robots, 'Robots.txt', :description => 'Add a robots.txt file to your site'
  module_for :sitemap, 'Site Map', :description => 'Add a Site Map to your site'

  def opensearch
    @node = SiteNode.find_by_id_and_module_name(params[:path][0],'/editor/opensearch') unless @node

    @page_modifier = @node.page_modifier

    @options = OpensearchOptions.new(params[:options] || @page_modifier.modifier_data || {})
    
    if request.post? && params[:options] && @options.valid?
      @page_modifier.update_attribute(:modifier_data,@options.to_h)
      expire_site
      flash.now[:notice] = 'Updated Options'
     end
  end
  
  class OpensearchOptions < HashModel
    attributes :title => nil, :description => nil, :search_results_page_id => nil, :icon_id => nil, :image_id => nil

    page_options :search_results_page_id

    validates_presence_of :search_results_page_id
    validates_length_of :title, :maximum => 64
    validates_length_of :description, :maximum => 1024

    def validate
      if self.title.blank?
	@config = Configuration.options
	self.title = @config.domain_title_name
	if self.title.blank?
	  @domain = Domain.find DomainModel.active_domain_id
	  self.title = @domain.name.humanize
	end
      end

      if self.description.blank?
	self.description = 'Search using %s' / self.title
      end

      if self.icon_id
	domain_file = DomainFile.find_by_id self.icon_id
	if domain_file
	  errors.add(:icon_id, 'invalid type (must be a favicon)') unless domain_file.mime_type == 'image/x-icon' || domain_file.mime_type == 'image/vnd.microsoft.icon'
	else
	  errors.add(:icon_id, 'missing')
	end
      end

      if self.image_id
	domain_file = DomainFile.find_by_id self.image_id
	if domain_file
	  errors.add(:image_id, 'invalid type (must be a jpeg or png)') unless domain_file.mime_type == 'image/jpeg' || domain_file.mime_type == 'image/png'
	  errors.add(:image_id, 'invalid size (must be 64x64)') unless domain_file.width == domain_file.height && domain_file.width == 64
	else
	  errors.add(:image_id, 'missing')
	end
      end
    end

  end

  def robots
    @node = SiteNode.find_by_id_and_module_name(params[:path][0],'/editor/robots') unless @node

    @page_modifier = @node.page_modifier

    @options = RobotsOptions.new(params[:options] || @page_modifier.modifier_data || {})
    
    if request.post? && params[:options] && @options.valid?
      @page_modifier.update_attribute(:modifier_data,@options.to_h)
      expire_site
      flash.now[:notice] = 'Updated Options'
     end
  end

  class RobotsOptions < HashModel
    attributes :extra => nil
  end

  def sitemap
    @node = SiteNode.find_by_id_and_module_name(params[:path][0],'/editor/sitemap') unless @node

    @page_modifier = @node.page_modifier

    @options = SitemapOptions.new(params[:options] || @page_modifier.modifier_data || {})
    
    if request.post? && params[:options] && @options.valid?
      @page_modifier.update_attribute(:modifier_data,@options.to_h)
      expire_site
      flash.now[:notice] = 'Updated Options'
     end
  end

  class SitemapOptions < HashModel
    attributes :extra => nil
  end
end
