
class Editor::SearchController < ParagraphController #:nodoc:all
  permit 'editor_editor'
  
  user_actions [:add_feature ]

  editor_header "Search Paragraphs"

  editor_for :search_box, :name => 'Search Box', :feature => :search_page_search_box

  editor_for :search_results, :name => 'Search Results', :feature => :search_page_search_results

  editor_for :opensearch_auto_discovery, :name => 'OpenSearch Autodiscovery Paragraph'

  class SearchBoxOptions < HashModel
    attributes :default_per_page => 10, :max_per_page => 50, :search_results_page_id => nil, :content_type_id => nil

    integer_options :default_per_page, :max_per_page

    page_options :search_results_page_id

    options_form(
                 fld(:search_results_page_id, :page_selector),
                 fld(:default_per_page, :select, :options => (1..50).to_a),
                 fld(:max_per_page, :select, :options => (1..50).to_a),
                 fld(:content_type_id, :select, :options => :content_type_options)
                 )

    def content_type_options
      ContentNodeSearch.content_types_options
    end
  end

  class SearchResultsOptions < HashModel
    attributes :default_per_page => 10, :max_per_page => 50, :search_results_page_id => nil, :content_type_id => nil, :search_order => 'results'

    integer_options :default_per_page, :max_per_page

    page_options :search_results_page_id

    options_form(
                 fld(:default_per_page, :select, :options => (1..50).to_a),
                 fld(:max_per_page, :select, :options => (1..50).to_a),
                 fld(:content_type_id, :select, :options => :content_type_options),
                 fld(:search_order, :select, :options => :search_order_options)
                 )

    def content_type_options
      ContentNodeSearch.content_types_options
    end

    def search_order_options
      [['By Score'.t,'score'],['By Date'.t,'date']]
    end
  end

  def opensearch_auto_discovery
    @options = OpensearchAutoDiscoveryOptions.new(params[:opensearch_auto_discovery] || @paragraph.data)
    if handle_paragraph_update(@options)
      DataCache.expire_content('Opensearch')
      return
    end
  end
  
  class OpensearchAutoDiscoveryOptions < HashModel
    attributes :module_node_id => nil
  
    options_form(
                 fld(:module_node_id, :select, :options => :opensearches, :label => 'Select OpenSearch', :description => 'which feed would you like to add autodiscovery for')
                 )
    
    def opensearches
      @opensearches ||= [['--Show All OpenSearches--']] + 
        SiteNode.find(:all,:conditions =>  ['node_type = "M" AND module_name = "/editor/opensearch"' ]).collect { |md| [md.node_path, md.id] }
    end
  end
end
