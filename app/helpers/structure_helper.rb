# Copyright (C) 2009 Pascal Rettig.

module StructureHelper #:nodoc:all
  @@element_icons = {:F => 'icons/framework.gif',
                     :P => 'icons/page.gif',
                     :R => 'icons/domain.gif',
                     :T => 'icons/template.gif',
                     :L => 'icons/lock.gif',
                     :M => 'icons/module.gif',
                     :J => 'icons/redirect.gif',
                     :D => 'icons/document.gif' }

  def display_structure(path,options = {},&block) 
    element_id_prefix = options[:prefix] || 'node_'
    class_prefix = options[:class_prefix] || ''
    onclick=options[:onclick] || ''
    last_node=(options[:last].nil?)?(true):(options[:last])
    
    
    node_style = (last_node)?"background-image:url(/images/icons/menu/last.gif); background-repeat:no-repeat;":"background-image:url(/images/icons/menu/line.gif); background-repeat:repeat-y;"
    
    pre = "<div id='#{element_id_prefix}#{path.id}' class='#{class_prefix}node' style='#{node_style}'>"
    
    if path.children.count > 0 
      pre += image_tag("icons/menu/last_open.gif", :class => "line_icon", :id => "toggle_#{path.id}", :onclick => (options[:toggle] || "toggleVisible(this);"))
    else 
      pre += image_tag("icons/menu/last.gif", :id => "toggle_#{path.id}",  :class => "line_icon")
    end 
    
    pre  += "<span class='#{class_prefix}node_title' id='#{element_id_prefix}_#{path.node_type}_#{path.id}'>"
    icon = image_tag(@@element_icons[path.node_type.to_sym], :class => 'action_icons')
    post = '<br/>'
    
    after = '</div>'
    if path.children.length > 0
        post += "<div id='#{element_id_prefix}children_#{path.id} ' class='#{class_prefix}node_children'>"
        after += '</div>'
    else 
        post += '</div>'
    end
   
   yield pre,icon,path,post
   
   
   path.children. each do |child|
      options[:last] = (path.children.last == child)
      if child
        display_structure(child,options,&block);
      end
   end
        
   if path.children.length > 0
    yield after,nil,nil,nil
   end
  end

end
