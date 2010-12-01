
class Editor::SitemapDispatcher < ModuleDispatcher

  available_pages ['/', 'sitemap', 'Site Map', 'Site Map', false]

  def sitemap(args)
    simple_dispatch(1,'editor/action','sitemap',:data => @site_node.page_modifier.modifier_data)
  end
end
