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

  def site_node_add_modifier(modifier,name,description)
   <<-EOF.html_safe
    <div class='add_mod_elem' id='add_#{modifier}'>
     <a href='javascript:void(0);' title='#{vh description.t}'><span class='site_node_modifier #{modifier}_modifier'></span> #{h name.t}</a></div>
   EOF
  end

  def site_node_add(node,name,description)
   <<-EOF.html_safe
    <div class='add_node_elem' id='add_#{node}'>
     <a href='javascript:void(0);' title='#{vh description.t}'><span class='site_node #{node}_node'></span> #{h name.t}</a></div>
   EOF
  end
  def site_module_add(mod)
   <<-EOF.html_safe
    <div class='add_module_elem' id='add_module_#{mod[:component]}_#{mod[:module]}'> <a href='javascript:void(0);'  title='#{ jh mod[:options][:description].t }'><span class='site_node module_node'></span> #{h mod[:name]} </a></div>
   EOF
  end

 def revision_saved_details(revision)
    "version #{revision.revision}, saved #{distance_of_time_in_words_to_now(revision.created_at)} ago by #{ revision.created_by ? revision.created_by.first_name : 'Unknown'.t}"
  end

  def path_name_helper(path)
   if path.node_type == 'R' 
     Configuration.domain
   elsif path.node_type == 'G' 
     path.title
   elsif path.node_path == "/"
     "Home Page".t
   else
     "/" + path.title
   end
  end
end
