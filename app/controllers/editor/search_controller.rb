
class Editor::SearchController < ParagraphController #:nodoc:all
  permit 'editor_editor'
  
  user_actions [:add_feature ]

  editor_header "Search Paragraphs"

  editor_for :search_box, :name => 'Search Box', :feature => :search_page_search_box

  editor_for :search_results, :name => 'Search Results', :feature => :search_page_search_results

  editor_for :opensearch_auto_discovery, :name => 'OpenSearch Autodiscovery Paragraph'

  class SearchBoxOptions < HashModel
    attributes :default_per_page => 10, :max_per_page => 50, :search_results_page_id => nil

    integer_options :default_per_page, :max_per_page

    page_options :search_results_page_id
  end

  class SearchResultsOptions < HashModel
    attributes :default_per_page => 10, :max_per_page => 50, :search_results_page_id => nil, :content_type_id => nil

    integer_options :default_per_page, :max_per_page, :content_type_id

    page_options :search_results_page_id
  end

  def opensearch_auto_discovery
    
    @options = OpensearchAutoDiscoveryOptions.new(params[:opensearch_auto_discovery] || @paragraph.data)
    if handle_paragraph_update(@options)
      DataCache.expire_content('Opensearch')
      return
    end
    
    @opensearches = [['--Show All OpenSearches--']] + 
                     SiteNode.find(:all,:conditions =>  ['node_type = "M" AND module_name = "/editor/opensearch"' ]).collect { |md|
                       [md.node_path, md.id] }
  end
  
  class OpensearchAutoDiscoveryOptions < HashModel
    default_options :module_node_id => nil
    
    integer_options :module_node_id
  
  end
end
