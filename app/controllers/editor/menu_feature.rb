# Copyright (C) 2009 Pascal Rettig.


class Editor::MenuFeature < ParagraphFeature

  # Menu Feature, Used for Menus and Automenus
  feature :menu, :default_data => {  :url => '/test',
                    :title => 'Menu Title',
                   :menu => [
                    { :title =>  'Section Title',
                      :link => '/sectionlink',
                      :menu => [
                       { :title => 'Subname',
                         :link => '/sectionlink/sublink' },
                       {  :title => 'Subname2',
                         :link => '/sectionlink/sublink2' }
                      ] },
                      {
                       :title => 'Section Title 2',
                       :link => '/section2link'
                      }
                    ] },
  :default_feature => <<-FEATURE
<div>
  <cms:section>
    <div class='menu_item'>
    <cms:link selected_class='selected'><cms:title/></cms:link>
    <cms:selected>
      <cms:section>
        &nbsp;&nbsp;<cms:link selected_class='selected'><cms:title/></cms:link><br/>
      </cms:section>
    </cms:selected>
    </div>
  </cms:section>
</div>
  FEATURE
  
   def item_selected(item,url)
     if item.has_key?(:selected)
      return item[:selected]
    elsif item[:link] == '/'
      return url == '/'
    elsif url.starts_with?(item[:link])
      return true
    else
      return false
    end
  end
  
   def menu_feature(data)
      webiva_feature('menu',data) do |c|
          c.define_tag 'section' do |tag|
            tag.locals.data ||= data
            if tag.locals.data[:menu]
              tag.locals.data[:menu].each_with_index do |itm,idx|
                if item_selected(itm,data[:url])
                  tag.locals.selected_index = idx + 1
                end              
              end
              c.each_local_value(tag.locals.data[:menu],tag,'data')
            end
          end
          
       c.define_tag('menu') do |tag|
         tag.locals.data ||= data
            if(tag.locals.data[:menu].is_a?(Array) && tag.locals.data[:menu].length > 0) 
              if tag.attr['popup']
                "<div id='pmenu_#{tag.locals.data.object_id}' style='display:none;'>" + tag.expand + "</div>"
              else
                tag.expand
              end
            else
              nil
            end
          end
          
          c.expansion_tag('section:selected') { |tag|  tag.locals.selected_index == tag.locals.index }
          c.expansion_tag('section:unselected') { |tag| tag.locals.selected_index != tag.locals.index }
          c.define_tag('section:next') { |tag| tag.locals.index == tag.locals.selected_index + 1 }
          c.define_tag('section:previous') { |tag| tag.locals.index == tag.locals.selected_index - 1 }
          
          
          c.define_value_tag 'section:color' do |tag|
            color_type=nil
            case tag.attr['type']
              when 'selected': color_type = :color_selected
              when 'hover': color_type = :color_hover
              else; color_type = :color
            end
            if tag.locals.data[:rev]
              tag.locals.data[:rev].send(color_type)
            else
              nil
            end
          end
          
          c.define_value_tag('section:field1')  { |tag| tag.locals.data[:rev] ? tag.locals.data[:rev].field1 : nil }
          c.define_value_tag('section:field2')  { |tag| tag.locals.data[:rev] ? tag.locals.data[:rev].field2 : nil }
          
          
          
          c.define_expansion_tag('member') do |tag|
            if tag.attr['profile_id'] 
              myself.user_profile_id == tag.attr['profile_id'].to_i 
            elsif tag.attr['not_profile_id']
              myself.user_profile_id!= tag.attr['not_profile_id'].to_i
            else
              myself.user_profile_id != 1
            end
          end
          
          c.define_image_tag 'section:img' do |tag|
            if tag.locals.data[:rev]
              attr = tag.attr.clone
              icon_type = attr.delete('icon')
              
              selected = attr.delete('selected')
              if selected && item_selected(tag.locals.data,data[:url])
                icon_type = selected
              end
              
              if %w(hot disabled selected).include?(icon_type)
                icon = tag.locals.data[:rev].send('icon_' + icon_type )
              else
                icon = tag.locals.data[:rev].icon
              end
              
              if rollover_type = tag.attr.delete('rollover') 
                @include_menu_js = true
                if %w(hot disabled selected).include?(rollover_type)
                  rollover_icon = tag.locals.data[:rev].send('icon_' + rollover_type )
                elsif 
                  rollover_icon = tag.locals.data[:rev].icon
                end
                
                rollover_icon ? [ icon, rollover_icon, "pmenu_#{tag.locals.data.object_id}" ] : icon
              else
                icon
              end
            else
              nil
            end
          end

 
          c.define_tag 'section:popup' do |tag|
            @include_menu_js = true
            opts = []
            opts << "offset_x: #{jvh tag.attr['offset_x']}" if tag.attr['offset_x']
            opts << "offset_y: #{jvh tag.attr['offset_y']}" if tag.attr['offset_y']
            opts << "position: \"#{jvh tag.attr['position']}\"" if tag.attr['position']
            opts = opts.join(", ")
            
            if editor?
              nil
            else
              "onmouseover='WebivaMenu.popupDiv(\"pmenu_#{tag.locals.data.object_id}\",this,{#{opts}});' onmouseout='WebivaMenu.hidePopupDiv(\"pmenu_#{tag.locals.data.object_id}\");'"
            end
          end
          
          c.link_tag('section:') do |tag|
             if data[:edit]
              if tag.locals.data[:type] == 'P'
                if tag.locals.data[:page]
                  { :href => tag.locals.data[:link], :onclick => "cmsEdit.reloadPage(\"page\",#{tag.locals.data[:page]}); return false;", :selected =>  item_selected(tag.locals.data,data[:url]) }
                else
                  { :href => tag.locals.data[:link], :onclick => "return false", :selected =>  item_selected(tag.locals.data,data[:url]) }
                end
              else
                "javascript:void(0);"
              end
            else
              { :href => tag.locals.data[:link], :selected =>  item_selected(tag.locals.data,data[:url]) }
            end          
          end
          
          c.define_tag 'section:title' do |tag|
            tag.locals.data[:title].to_s.gsub("\n","<br/>")
          end
          c.define_tag 'section:description' do |tag|
            tag.locals.data[:description].to_s.gsub("\n","<br/>")
          end
          
          define_position_tags(c)
        end
    end
  
end
