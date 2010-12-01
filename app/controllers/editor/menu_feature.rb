# Copyright (C) 2009 Pascal Rettig.


class Editor::MenuFeature < ParagraphFeature #:nodoc:all

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
<ul class='menu'>
  <cms:section>
    <li><cms:link selected_class='selected'><cms:title/></cms:link>
    <cms:menu><ul> <cms:section>
        <li><cms:link selected_class='selected'><cms:title/></cms:link></li>
     </cms:section></ul></cms:menu>
     </li>
  </cms:section>
</ul>
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
              
              if rollover_type = attr.delete('rollover') 
                require_js('menu') unless @include_menu_js
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
            require_js('menu') unless @include_menu_js
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
        end
    end
  

 # Bread Crumbs Feature
  feature :bread_crumb, :default_data => { :parents => [ 
                                      { :title => 'Root',  :link => "/" },
                                      { :title => 'Parent', :link => "/sub" }
                                     ],
                                     :current => { :title => 'Current Page',
                                                   :link => '/sub/goober' }
                                  },
    :default_feature => <<-FEATURE
  <div>
    <cms:parent>
      <cms:level value='1'>
        <b><a <cms:href/> ><cms:title/></a></b> &gt;
      </cms:level>
      <cms:not_level value='1'>
        <a <cms:href/> ><cms:title/></a> &gt; 
      </cms:not_level>
    </cms:parent>
    <cms:current>
      <cms:title/>
    </cms:current>
  </div>
FEATURE
  
  def bread_crumb_feature(data)
   webiva_feature('bread_crumb',data) do |c|
        c.define_tag 'parent' do |tag|
          # Go through each section
          # Set the local to this
          result = ''
          mnu = (tag.globals.data || data)[:parent]
          if mnu.is_a?(Array)
            mnu.each_with_index do |entry,idx|
              tag.locals.level = idx + 1
              tag.locals.data = entry
              tag.locals.first = entry == mnu.first
              tag.locals.last =  entry == mnu.last
              result << tag.expand
            end
          end
          result
        end
        
        c.define_tag 'current' do |tag|
            tag.locals.data = (tag.globals.data || data)[:current]
            tag.locals.first = true
            tag.locals.last = true
            tag.expand
        end
        
        c.define_tag 'href' do |tag|
          if data[:edit]
            if tag.locals.data[:page]
              "href='#{tag.locals.data[:link]}' onclick='cmsEdit.reloadPage(\"page\",#{tag.locals.data[:page]}); return false;'"
            else
              "href='#{tag.locals.data[:link]}' onclick='return false;'"
            end
          else
            "href='#{tag.locals.data[:link]}'"
          end
        end
        
        c.define_tag 'level' do |tag|
          if tag.locals.level == tag.attr[:value].to_i
            tag.expand
          else
            ''
          end
        end
        
        c.define_tag 'not_level' do |tag|
          if tag.locals.level != tag.attr[:value].to_i
            tag.expand
          else
            ''
          end
        end
        
        c.define_tag 'url' do |tag|
          tag.locals.data[:link]
        end
        
        c.define_tag 'title' do |tag|
          tag.locals.data[:title]
        end
        
        c.define_tag 'menu_title' do |tag|
          tag.locals.data[:menu_title]
        end 
      end
      
  end


  feature :page_title, :default_feature => <<-FEATURE
   <h1><cms:title/></h1>
FEATURE

  def page_title_feature(data)
    webiva_feature('page_title') do |c|
      c.h_tag('title') { |t| data[:title] }
    end
  end



  # Site Map Feature
  feature :site_map, :default_data => { :entries => [ 
                                      { :title => 'Home Page', :level => 1, :link => "/" },
                                      { :title => 'Sub Page 1', :level => 2, :link => "/sub" },
                                      { :title => 'Sub Page 2', :level => 2, :link => "/sub2" }
                                     ]  
                                  },
    :default_feature => <<-FEATURE
  <div>
    <cms:entry>
      <div style="padding-left:<cms:level factor='10'/>px">
      <a <cms:href/>><cms:title/></a> 
      <cms:languages>
        ( <cms:language> <a <cms:href /> ><cms:title/></a> <cms:not_last>,</cms:not_last></cms:language> )
     </cms:languages>
      </div>     
    </cms:entry>
  </div>
FEATURE
  
  
  def site_map_feature(data)
    webiva_feature('site_map',data) do |c|
      c.define_tag 'entry' do |tag|
        mnu = (tag.globals.data||data)[:entries]
        c.each_local_value(mnu,tag,'data')
      end
      
      c.define_tag 'href' do |tag|
        if data[:edit]
          if tag.locals.data[:page]
            "href='#{tag.locals.data[:link]}' onclick='cmsEdit.reloadPage(\"page\",#{tag.locals.data[:page]}); return false;'"
          else
            "href='#{tag.locals.data[:link]}' onclick='return false;'"
          end
        else
          "href='#{tag.locals.data[:link]}'"
        end
      end
      
      
      c.define_tag 'level' do |tag|
        if !tag.single?
          tag.locals.data[:level] == (tag.attr['value'] || 1).to_i  ? tag.expand : nil
        else
          tag.locals.data[:level] * (tag.attr['factor'] || 1).to_i
        end
      end
      
      c.define_tag('url') {  |tag| tag.locals.data[:link] }
      c.define_tag('title') { |tag|  tag.locals.data[:title] }
      
      c.define_value_tag('description') { |tag| tag.locals.data[:description] }
      c.define_value_tag('keywords') { |tag| tag.locals.data[:keywords] }
      c.define_value_tag('page_title') { |tag| tag.locals.data[:page_title] }
      
      c.define_expansion_tag('languages') { |tag| tag.locals.data[:languages].is_a?(Array) }
      
      c.define_tag 'language' do |tag|
        mnu =tag.locals.data[:languages] 
        c.each_local_value(mnu,tag,'data')
      end
    end
  end


end
