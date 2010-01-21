
class Editor::OpensearchDispatcher < ModuleDispatcher #:nodoc:all

  available_pages ['/', 'opensearch', 'Open Search', 'Open Search',false]

  def opensearch(args)
    simple_dispatch(1,'editor/search','opensearch',:data => @site_node.page_modifier.modifier_data)
  end
end
