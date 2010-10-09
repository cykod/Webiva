
class Editor::RobotsDispatcher < ModuleDispatcher

  available_pages ['/', 'robots', 'Robots.txt', 'Robots.txt', false]

  def robots(args)
    simple_dispatch(1,'editor/action','robots',:data => @site_node.page_modifier.modifier_data)
  end
end
