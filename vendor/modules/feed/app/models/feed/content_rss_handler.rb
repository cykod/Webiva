# Copyright (C) 2009 Pascal Rettig.


class Feed::ContentRssHandler

  def self.feed_rss_handler_info
    {
    :name => "Custom Content RSS Feed"
    }
  end

  def initialize(options)
    @options = options
    @feed_id = @options.feed_identifier
    @feed_content_model_id,@feed_site_node,@feed_pub_id,@detail_page_id,@detail_pub_id = @feed_id.split(",")
  end
  
  def get_feed
    @content_model = ContentModel.find_by_id(@feed_content_model_id)
    @list_page = SiteNode.get_node_path(@feed_site_node)
    @detail_page = SiteNode.get_node_path(@detail_page_id)
    
    @list_publication = @content_model.content_publications.find_by_id(@feed_pub_id)
    @detail_publication = @content_model.content_publications.find_by_id(@detail_pub_id)
    
    limit = @options.limit > 0 ? @options.limit : 10
    
    @list_revision = PageRevision.find(:first, :joins => :page_paragraphs,
                          :conditions => ['display_module = "/editor/publication" AND display_type = "list" AND page_revisions.revision_container_id = ? AND page_revisions.revision_container_type = "SiteNode" AND page_revisions.active=1 AND revision_type="real"',@feed_site_node])
    @list_paragraph = @list_revision.page_paragraphs[0] if @list_revision
    
    
    if @list_page && @detail_page && @list_publication && @detail_publication && @list_paragraph
      data = { :title => @options.feed_title.blank? ? @list_publication.name : @options.feed_title,
               :link => Configuration.domain_link(@list_page),
               :items => []}
               
      list_data, entries = @list_publication.get_list_data(nil,@list_paragraph.data || {})
      @detail_publication.data ||= []
      title_field = @content_model.content_model_fields.find_by_id(@detail_publication.data[:title_field])
      description_field = @content_model.content_model_fields.find_by_id(@detail_publication.data[:description_field])
      published_at_field = @content_model.content_model_fields.find_by_id(@detail_publication.data[:published_at_field])
      
      entries.each do |entry|
        
        item = { } 
        item[:title] = entry.send(title_field.field) if title_field
        begin
          item[:published_at] = entry.send(published_at_field.field).to_s(:rfc822) if published_at_field 
        rescue Exception => e
          # If we don't have a valid date
        end
        item[:description] = entry.send(description_field.field) if description_field
        
#        post.blog_categories.each do |cat|
#          item[:categories] ||= []
#          item[:categories] << cat.name
#        end
        item[:link] = Configuration.domain_link(@detail_page + "/" +  entry.id.to_s) if @detail_page
        item[:guid] = item[:link]
        data[:items] << item
      end
      
      data
    else
      data = { :title => 'Invalid Rss Feed',
               :link => Configuration.domain_link(@list_page),
               :items => [] }
    end
  end

  class Options < Feed::AdminController::RssModuleOptions
    attributes :feed_identifier => nil, :limit => 10

    validates_presence_of :feed_identifier, :limit
    validates_numericality_of :limit

    integer_options :limit

    options_form(fld(:feed_identifier, :select, :options => :feed_identifier_options, :label => 'Feed'),
		 fld(:limit, :text_field)
		 )

    def validate
      if self.feed_identifier
	errors.add(:feed_identifier) unless self.feed_identifier_options.rassoc(self.feed_identifier)
      end
    end

    def feed_identifier_options
      revisions = PageRevision.find(:all,:joins => :page_paragraphs,
				    :conditions => 'page_paragraphs.display_module = "/editor/publication" AND display_type = "list" AND page_revisions.active=1 AND revision_type="real"')

      opts = [['--Select Feed--', nil]]

      revisions.each do |rev|
	par = rev.page_paragraphs[0]
	pub = ContentPublication.find_by_id(par.content_publication_id) if par
	detail_page = par.data[:detail_page] if par && par.data[:detail_page]

	if detail_page
	  detail_revision = PageRevision.find(:first,:joins => :page_paragraphs,
					      :conditions => ['display_module = "/editor/publication" AND display_type = "view" AND page_revisions.revision_container_id = ? AND page_revisions.revision_container_type = "SiteNode" AND page_revisions.active=1 AND revision_type="real"',detail_page])
	  detail_par = detail_revision.page_paragraphs[0] if detail_revision
	  
	  if par && pub && rev.revision_container.is_a?(SiteNode) && detail_revision && detail_par
	    opts << [ "#{pub.content_model.name} #{pub.name} - #{rev.revision_container.node_path}", "#{pub.content_model_id},#{rev.revision_container_id},#{pub.id},#{detail_page},#{detail_par.content_publication_id}" ]
	  end
	end
      end
      opts
    end
  end
end
