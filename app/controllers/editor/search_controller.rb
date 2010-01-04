
class Editor::SearchController < ParagraphController
  permit 'editor_editor'
  
  user_actions [:add_feature ]

  editor_header "Search Paragraphs"

  editor_for :search_box, :name => 'Search Box', :feature => :search_page_search_box

  editor_for :search_results, :name => 'Search Results', :feature => :search_page_search_results


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

end
