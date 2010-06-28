# Copyright (C) 2009 Pascal Rettig.


class Feed::DataOutputDispatcher < ModuleDispatcher
  

  available_pages ['/', 'data_output' ,'Data Output','Data Output',false]
                  
 
  def data_output(args)
    @site_node.page_modifier.modifier_data ||= {}
  
    simple_dispatch(1,'editor/publication','data_output',:data => @site_node.page_modifier.modifier_data, :content_publication_id => @site_node.page_modifier.modifier_data[:data_publication_id].to_i, :site_feature_id => @site_node.page_modifier.modifier_data[:site_feature_id].to_i )
  end

end
