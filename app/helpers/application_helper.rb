# Copyright (C) 2009 Pascal Rettig.


# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  include StyledFormBuilderGenerator::FormFor
  
  include EscapeHelper

   class PopupMenuBuilder 
      include ActionView::Helpers::JavaScriptHelper
     
     def link(name,options = {})
        if options[:js]
          "[ '','#{escape_javascript(name)}', 'js', '#{escape_javascript(options[:js])}' ],"
        elsif options[:url]
          "[ '','#{escape_javascript(name)}',  '#{escape_javascript(options[:url])}', ],"
        end
     end
     
     def separator() 
        "[],"
     end  
   end
   
   def popup_menu(id,image,options={},&block)
      options = options.clone
      options[:class] = 'line_icon'
    
      concat("<a href='javascript:void(0);' id='link_#{id}' >" + image_tag(image,options) + "</a>")
      concat("<script type='text/javascript'> $('link_#{id}').onclick = function() { popupMenu('', new Array(")
      
      yield PopupMenuBuilder.new
      
      concat("[] )); }</script>")
   end

   def action_panel(options = {},&block)
      concat("<div class='admin_content'><ul class='action_panel'>")
      
      apb = ActionPanelBuilder.new(self)
      yield apb
      
      if options[:handler]
        handlers = get_handler_info('action_panel',options[:handler])
      
        if handlers
          handlers.each do |handler|
            (handler[:links] || []).each do |link|
              opts = link.clone
              name = opts.delete(:link)
              role = opts.delete(:role)
              
              if !role || myself.has_role?(role)
                concat(apb.link(name,opts))
              end
            end
          end
        end
      end
      
      
      
      
      concat("</ul></div>")
   end   
   
   class ActionPanelBuilder 
      def initialize(ctrl)
        @ctrl = ctrl
      end
    
      def link(txt,options = {},html_options = {})
        opts = options.clone
        icon = opts.delete(:icon)
        txt = txt.t unless opts.delete(:no_translate)
        right = "class='right'" if opts.delete(:right)
        
        if options[:url]
          opts = options[:url]
        end
        icon =  @ctrl.theme_icon("action","icons/actions/" + icon) if icon
        return "<li #{right}>" + @ctrl.send(:link_to,icon.to_s + @ctrl.send(:h,txt),opts,html_options) + "</li>"
      end
      
      def custom(&block)
        @ctrl.concat("<li>")
        yield 
        @ctrl.concat("</li>")
      end
   end
   
   class JSONUpdaterBuilder
      include ActionView::Helpers::TextHelper
      include ActionView::Helpers::UrlHelper
      
      def initialize(controller,options = {})
        @controller = controller
        @options = options
      end
      
      def func(name,args)
          args = [ args ] unless args.is_a?(Array)
          url_hash = @options[:url].clone || {}
          url = @controller.url_for( url_hash.merge(:action => name ) )
          
         str = <<EOF
#{name.camelcase(:lower)}: function(#{args.join(",")}) {
        params = $H({#{args.collect { |arg| arg + ":" + arg }.join(",\n")} });
                  
        new Ajax.Updater("#{@options[:update]}",
                        "#{url}",
                        { parameters: params.toQueryString(),
                          evalScripts: true 
                         });
         },
EOF
        str
      end
      
      def frm_func(name,options = {},&block)
          url_hash = @options[:url].clone || {}
          url = @controller.url_for( url_hash.merge(:action => name ) )
          func_str = <<EOF
#{name.camelcase(:lower)}: function(frm) {
        params = Form.serialize(frm);
EOF
      
        concat(func_str)
        if options[:before] 
          yield block
        end
        
        update_str = <<EOF
        new Ajax.Updater("#{@options[:update]}",
                        "#{url}",
                        { parameters: params,
                          evalScripts: true 
                         });
EOF
        
        concat(update_str)
              
        if !options[:before]
          yield block
        end
        
        concat("},\n")
      end
      
      def custom_func(name,args,options = {},&block)
          args = [ args ] unless args.is_a?(Array)
          url_hash = @options[:url].clone || {}
          url = @controller.url_for( url_hash.merge(:action => name ) )
         func_str = <<EOF
#{name.camelcase(:lower)}: function(#{args.join(",")}) {
        params = $H({ #{args.collect { |arg| arg + ":" + arg }.join(",\n")} });
EOF

        concat(func_str)
        if options[:before] 
          yield block
        end
        
        update_str = <<EOF
        new Ajax.Updater("#{@options[:update]}",
                        "#{url}",
                        { parameters: params.toQueryString(),
                          evalScripts: true 
                         });
EOF
        
        concat(update_str)
              
        if !options[:before]
          yield block
        end
        
        concat("},\n")
        
      end
    end
   
   def json_updater(name,options = {},&block) 
    concat("#{name} = {\n")
    
    yield JSONUpdaterBuilder.new(@controller,options)
    
    concat("dummy: null\n");
    concat("};");
   end
   
   class AjaxTabBuilder
      include ActionView::Helpers::TextHelper
		def initialize(view,tab_cnt,selected)
		  @view = view
			@tab_num = 0
			@selected = selected
			@tab_cnt = tab_cnt		
		end
		
		def tab(&block)
			@view.concat("<tr #{'style="display:none;"' unless @tab_num  == @selected}><td class='content' colspan='#{@tab_cnt+2}' >")
			@tab_num +=1;
			yield block
			@view.concat("</td></tr>")
		end
		def tabled_tab(&block)
			@view.concat("<tr #{'style="display:none;"' unless @tab_num  == @selected}><td class='content' colspan='#{@tab_cnt+2}' ><table>")
			@tab_num +=1;
			yield block
			@view.concat("</table></td></tr>")
		end
		
		def visible(&block)
			@view.concat("<tr><td class='content' colspan='#{@tab_cnt+2}' >")
			@tab_num +=1;
			yield block
			@view.concat("</tr></td>")
		end
   end
   
   def tabled_ajax_tabs(options,selected,&block)
    concat("<tr><td colspan='2'>")
    ajax_tabs(options,selected,&block)
    concat("</td></tr>")
   end
   
   def ajax_tabs(options,selected,&block) 
   		concat("<table class='ajax_tabs' cellpadding='0' cellspacing='0'><tr><td class='normal'>&nbsp;</td>")
   		selected_id = nil
   		options.each_with_index do |opt,idx|
          js= '' 
          if opt.is_a?(Array)
            js = opt[1]
            opt = opt[0]
          end
   				selected_id = idx if opt == selected
   				
   				concat("<td #{opt==selected ? 'class="selected"' : 'class="normal"'}> <a class='ajax_link' onclick='SCMS.select_tab(this); #{js}' href='javascript:void(0);'>#{opt.t}</a></td>")
   		end
   		concat("<td class='extra'> &nbsp; </td>	</tr>")
   		yield AjaxTabBuilder.new(self,options.length,selected_id)
   		concat("</table>")
   end
   
   class StatViewer
      include ActionView::Helpers::TagHelper
      
      def initialize
        @headers = 0
      end
    
     def row(label,stat,options = {})
        "<tr><td class='label'  valign='baseline' nowrap='1'>#{h label.t}:</td><td  class='stat' #{"align='#{options[:align]}'" if options[:align]} >#{h stat}</td></tr>"
     end  
     
     def raw(label,stat,options = {})
        "<tr><td  class='label' valign='baseline' nowrap='1'>#{h label.t}:</td><td  class='stat' #{"align='#{options[:align]}'" if options[:align]}>#{stat}</td></tr>"
     end
     
     def header(label)
      @headers += 1
      "#{'<tr><td class=\'spacer\' colspan=\'2\'></td></tr>' if @headers > 1}
      <tr><td class='header' colspan='2'><b>#{h label.t}</b></td></tr>"
     end
   
   end
   
   def stat_view(&block)
    concat("<table cellspacing='0' cellpadding='0' class='stat_viewer'>")
    yield StatViewer.new
    concat("</table>")
   end
   
   class ListBuilder
      include ActionView::Helpers::JavaScriptHelper
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::AssetTagHelper
      
      def initialize(form_obj,list_id,list_value)
        @list_id = list_id
        @list_value = list_value
        @form_obj = form_obj
      end
   
      def item(item_id,item_text,icon = nil)
        if icon
          icon = "<img src='#{icon}' />  "
        else
          icon = ''
        end
       "<div onclick='#{@list_id}_click(this)'>#{icon}#{item_text}<input type='hidden' name='#{@form_obj}[#{item_id}]' value='#{@list_value}' </div>"
      end
         
   end
   
   def selected_list(title,list_id,form_obj,&block)
      concat("<div class='selected_list_title'> #{title} <div id='selected_#{list_id}' class='selected_list'>")
      yield ListBuilder.new(form_obj,list_id,1)
      concat("</div></div>")
      concat("<script> #{list_id}_click = function(elem) { var tgt = $(elem.parentNode.id == 'selected_#{list_id}' ? 'unselected_#{list_id}' : 'selected_#{list_id}'); tgt.appendChild(elem); var inpt = elem.getElementsByTagName('input')[0]; inpt.value = (inpt.value == '1')?'0':'1' }; </script>");
   end
   
   def unselected_list(title,list_id,form_obj,&block)
      concat("<div class='selected_list_title'> #{title} <div id='unselected_#{list_id}' class='selected_list'>")
      yield ListBuilder.new(form_obj,list_id,0)
      concat("</div></div>")
   end
   
  
    def show_popup_options(elem_id,elem_function,icons,args,links = [])
    
      link_str = "," + menu_popup_args(links) if links.size > 0
      
      str = "popupOptions('#{elem_id}','#{elem_function}',[ '" + icons.join("','") + "'],'#{args}'#{link_str});";
      
      return str;
    
    end
    
    def menu_popup_args(links) 
      str = 'new Array(';
    
      links.each { |lnk|

          if(lnk.is_a?(Array)) 

            if(lnk.size == 0)
                str += " [] "
            elsif lnk.size ==3 && lnk[1] == 'js'
                str += " [ '', '" + escape_javascript(lnk[0])  + "','js','" + escape_javascript(lnk[2]) + "' ]"
            else
                str += " [ '', '" + escape_javascript(lnk[0])  + "','" + escape_javascript(lnk[1]) + "' ]"
            end

            if lnk != links.last
              str += ", "
            end
          end
      } 
      
      str += ')'
      
      str
    
    end
    
    


   def menu_popup(image,id,links,options = {}) 

      str = "<a href='javascript:void(0);' id='link_#{id}' >" + image_tag(image,:class =>  "line_icon") + "</a>"
      str += "<script type='text/javascript'> $('link_#{id}').onclick = function() { SCMS.popup(new Array("

      links.each { |lnk|

          if(lnk.is_a?(Array)) 

            if(lnk.size == 0)
                str += " [] "
            elsif lnk.size ==3 && lnk[1] == 'js'
                str += " [ '" + escape_javascript(lnk[0])  + "','js','" + escape_javascript(lnk[2]) + "' ]"
            else
                str += " [ '" + escape_javascript(lnk[0])  + "','" + escape_javascript(lnk[1]) + "' ]"
            end

            if lnk != links.last
              str += ", "
            end
          end
      } 

      str += ' ) ); };'

      if(options[:double_click]) 
        str += "$('link_#{id}').ondblclick  = function() { #{options[:double_click]};  cClick(); };";
      end

      str += '</script> '

      str

   end
   
   def js_popup(image,action) 
    "<a href='javascript:void(0);' onclick='#{h action}'>" + image_tag( image, :align => 'middle' ) + '</a>'
   end

   def sidebar(title,id,display=true)
      className = display ? 'sidebar':'sidebar_closed'

      str = %Q{<div class="#{className}" id="#{id}">
                  <div class='st' onclick="menuClick(this)">#{title}</div>
                  <div class='sb'>
                  }
      str

   end

   def end_sidebar
      "</div></div>"
   end
   
   def link_to_remote_with_overlay(name, url = {}, html_options = {})
      link_to_function(name, remote_function(:update => "boxcontent", :loading => "showLoader
    ()", :complete => "showBox()", :url => url))
   end
   
   def execute_overlay(url = {}) 
    remote_function(:update => "boxcontent", :loading => "showLoader()", :complete => "showBox()", :url => url)
   end
   
   def js_execute_overlay(js_url_var) 
     "new Ajax.Updater('boxcontent', #{js_url_var}, {asynchronous:true, evalScripts:true, onComplete:function(request){showBox()}, onLoading:function(request){showLoader()}});"
   end

   def cms_dropdown(dropdown_id,style='',options = {})
      str = "<span class='cms_dropdown'  onmouseout=\"delayedHide($('#{dropdown_id}'));\"  onmouseover=\"delayedHideShow($('#{dropdown_id}'));\">" 
      str += "<span class='cms_dropdown_display' #{"onclick=\"displayDropdown('#{dropdown_id}')\"" if options[:first_element]} >#{options[:first_element] || "-------------------------"}</span>"
      str += "<span class='cms_dropdown_image' >" + image_tag('icons/dropdown.gif', :onclick => "displayDropdown('#{dropdown_id}')") + "</span>" unless options[:first_element]
      str += "<ul id='#{dropdown_id}' style='display:none; #{style}'>"
      
      str
   end
   
   def end_cms_dropdown(dropdown_id,options = {})
      str = '</ul></span>'
      if(!options[:skip_script])
        str += "<script type='text/javascript'>var elem = getChild($('#{dropdown_id}'),'cms_dropdown_selected'); "
        str += " if (!elem) { elem = getChildElements($('#{dropdown_id}'))[0]; } "
        str += " var selected = getChild($('#{dropdown_id}').parentNode,'cms_dropdown_display'); "
        str += " selected.innerHTML=elem.innerHTML; </script> ";
      end
      
      str
   end
   
   def domain_file_url(object,size = nil)
   		object.url(size)
   end 
   
   def nl2br(string)
     h(string).gsub("\n\r","<br>").gsub("\r", "").gsub("\n", "<br />")
   end   


  def table_for(objects, columns, options = {}, &block)
    row = options.delete(:row)
    end_row = options.delete(:end_row)
    
    concat("<table cellpadding='0' cellspacing='0' #{options.collect { |key,val| "#{key}='#{h(val)}'" }.join(' ')}><thead><tr>")
    columns.each do |col|
      if col.empty?
        concat("<th class='empty'></th>")
      else
        concat("<th #{"class='first'" if col==columns.first}>#{col.t}</th>")
      end
    end 
    concat('</tr></thead><tbody>')
    
    objects.each do |obj|
      concat(row) if row
      yield obj
      concat(end_row) if end_row
    end 
    
    
    concat('</tbody></table>')
  end 
  
   def escape_javascript(javascript)
         (javascript || '').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
   end
   
   def paction_field(paragraph_id)
    "<input type='hidden' name='paction' value='#{paragraph_id}' />"
   end
   
   
  def base_language_only
    yield if Locale.base?
  end

  def not_base_language
    yield unless Locale.base?
  end
  
  def dec(number)
    number ? sprintf("%0.2f",number) : '0.00' 
  end
  
  def hide_if(val)
  	val ? "style='display:none;'" : ''
  end
  
  def hide_unless(val)
   hide_if(!val)
  end
  
  def basic_help(name,&block) 
  js = <<JAVASCRIPT
  <a href='javascript:void(0);' onclick='Element.hide(this); Element.show("#{name.to_s}");' >+ Show Basic Help</a>
			<div id='#{name.to_s}' style='display:none;'>
JAVASCRIPT
  	concat(js)
  	yield
  	concat("</div>")
  	
  end
  
  
  def highlight_row(elem_type,elem_id,options={})
  
    <<-JAVASCRIPT
    id='elem_#{elem_type}_#{elem_id}_row' onmouseover='SCMS.highlightRow(this);'  onmouseout='SCMS.lowlightRow(this#{ ',"' + jh(options[:clear_callback]) + '"' if options[:clear_callback]});' onclick='SCMS.clickRow("#{elem_type}","#{elem_id}"); #{options[:callback].to_s.gsub("'",'&apos;')}'

    JAVASCRIPT
  end
  
  def entry_checkbox(elem_type,elem_id) 
    <<-JAVASCRIPT
        <input type='checkbox' class='entry_checkbox' name='#{elem_type}[#{elem_id}]' value='#{elem_id}' id='elem_#{elem_type}_#{elem_id}' onclick='this.checked = !this.checked;'  />    
    JAVASCRIPT
  end
  
  def pagination(path,page_hash)
  
    display_pages = page_hash[:window_size].to_i
    page = page_hash[:page]
    pages = page_hash[:pages]
      
      result = ''
      
      if pages > 1
        
        # Show back button
        if page > 1
          result += "<a href='#{path}?page=#{page-1}'>&lt;&lt;</a> "
        end
        # Find out the first page to show
        start_page = (page - display_pages) > 1 ? (page - display_pages) : 1
        end_page = (start_page + (display_pages*2))
        if end_page > pages
          start_page -= end_page - pages - 1
          start_page = 1 if start_page < 1 
          
          end_page = pages
        end
        
        if start_page == 2
          result += " <a href='#{path}?page=1'> 1 </a> "
        elsif start_page > 2
          result += " <a href='#{path}?page=1'> 1 </a> .. "
        end
        
        (start_page..end_page).each do |pg|
          if pg == page
            result += " <b> #{pg} </b> "
          else
            result += " <a href='#{path}?page=#{pg}'> #{pg} </a> "
          end
        end
        
        if end_page == pages - 1
          result += " <a href='#{path}?page=#{pages}'> #{pages} </a> "
        elsif end_page < pages - 1
          result += " .. <a href='#{path}?page=#{pages}'> #{pages} </a> "
        end
        
        # Next Button
        if page < pages
          result += " <a href='#{path}?page=#{page+1}'>&gt;&gt;</a> "
        end
      end
      
      result  
  
  end

  def admin_pagination(callback,pages,options = {})
    output = ''
    if pages[:pages] > 1

        window_size = options[:window_size] || 5

        page = (pages[:page] || 1).to_i
        pages_count = pages[:pages]
        pages_count = 1 if pages_count < 1
        
        if(page < 1)
          page = 1
        elsif page > pages_count
          page = pages_count
        end
        
        # Find out the first page to show
        start_page = (page - window_size - 1) > 1 ? (page - window_size - 1) : 1
        end_page = (start_page + (window_size*2) + 1)
        if end_page > pages_count - 1
          start_page -= end_page - pages_count 
          start_page = 1 if start_page < 1 
          end_page = pages_count
        end

      pages_list = (start_page..end_page).to_a

      output << "<ul class='pagination'>"
      initial = true
      if(pages[:page] > 1)
        initial = false
        output <<   "<li class='first highlight'><a href='javascript:void(0);' onclick='#{callback.call(pages[:page]-1)}'>&lt;</a></li>"
      end
      output <<  pages_list.collect  {  |number| 
               first = true if initial
               initial = false
               if number.to_i == pages[:page].to_i 
                 "<li class='#{first ? "first " : ""}current'>#{number.to_s}</li>"
               elsif number.is_a?(String)
                 "<li class='spacer'>#{number}</li>"
               else
                 "<li class='#{first ? "first " :  ""}'><a href='javascript:void(0);' onclick='#{callback.call(number)}'>#{number}</a></li>"
               end
               
             }.to_s 
      if(pages[:page] < pages[:pages])
        output <<  "<li class='highlight'><a href='javascript:void(0);' onclick='#{callback.call(pages[:page]+1)}')'>&gt;</a></li>"
      end
      output << '</ul>'
    end
    output
  end
  
  def ago_format(sec_diff)
    min_diff = (sec_diff / 60).floor
    
    
    days_ago = (min_diff / (60 * 24)).floor
    min_diff = min_diff % (60 * 24)
    
    hours_ago = (min_diff / 60).floor
    min_ago = min_diff % 60
    
    output = ''
    if days_ago > 0
      output  << "%d day" / days_ago
      output << ", "
    end
    output << sprintf("%d:%02d",hours_ago,min_ago)
    
    output
  end

  def theme_stylesheet_link_tag(stylesheet,options={})
    stylesheet_link_tag "/themes/#{theme}/stylesheets/#{stylesheet}" ,options
  end



  def theme_image_tag(img,options = {})
    options[:align] = 'absmiddle' unless options[:align]
    if img[0..6] == "/images"
      image_tag("/themes/#{theme}" + img,options)
    else
      image_tag("/themes/#{theme}/images/" + img,options)
    end
  end

  
  def theme_icon(image_type,img,options={}) 
   options[:align] = 'absmiddle' unless options[:align]
   if img[0..6] == "/images"
      image_tag("/themes/#{theme}" + img,options)
    else
      image_tag("/themes/#{theme}/images/" + img,options)
    end
  end

 
  
  def admin_form_for(name,obj=nil,options={},&block)
    options[:html] ||= {}
    options[:html][:class] = 'admin_form'
    
    cms_form_for(name,obj,options,&block)
  end
  
  def admin_fields_for(name,obj=nil,options={},&block)
    concat("<table class='styled_table admin_form'>")
    cms_subfields_for(name,obj,options,&block)
    concat("</table>")
  end
  
  
  # Display an escaped value or a default value
  def v(val,empty_val = '-')
    if val.blank?
      empty_val
    else
      h(val)
    end
  end
  
  
  def subpage_display(name,pages)
    output = "<table class='action_icon_table'><tr>"
    
    idx = -1
    
    pages = pages.clone
    handlers = get_handler_info(:navigation,name)
  
    (handlers||[]).each do |handler|
      pages += handler[:pages] if handler[:pages].is_a?(Array)
    end
      
    
    
    html = pages.collect do |pg|
      idx += 1
      if myself.has_role?(pg[1].to_s)
        pg_html = <<-OUTPUT
          <td><a href='#{url_for pg[3]}' onmouseover='SCMS.show_hide("subpage_#{idx}","subpage_none");' onmouseout='SCMS.show_hide("subpage_none","subpage_#{idx}");'>#{theme_image_tag "actions/" + pg[2]}<br/>#{pg[0].t}</a></td>
        OUTPUT
        help = "<div class='action_icon_mouseover' id='subpage_#{idx}' style='display:none;'>#{h(pg[4])}</div>"
        [ pg_html, help ]
      else 
        [ '','' ]
      end
    end
    
         
    output +=  html.map { |elm| elm[0] }.join
    output += "</table><div class='action_icon_mouseover' id='subpage_none'></div>"
    output += html.map { |elm| elm[1] }.join
    output
  end
  
  def list_format(txt)
    "<ul>" + txt.split("\n").map { |elm| "<li>#{h elm}</l1>" }.join("\n") + "</ul>"
  end
  
  
def active_table_for(name,active_table_output,options={},&block)
      options = options.clone 

      pagination = active_table_output.paging
      objects = active_table_output.data
      columns = active_table_output.column_instances

      table_actions = options.delete(:actions)
      more_actions = options.delete(:more_actions)

      options[:class] ||= "active_table"

      form_elements = options.delete(:form_elements)
      
      paction=options.delete(:paction)
      refresh_url = options.delete(:refresh_url)  || url_for(:action => "display_#{name.to_s}")
      update_element = options.delete(:update) || name.to_s

      existing_search = []

      search_idx=0
      search_str = columns.collect() do |col| 
          col.header.active_table = name
          srch = col.search_html
          searching = col.searching
          search_idx += 1 if searching
          if searching
            existing_search << "(#{col.header.name}:  <a href='javascript:void(0);' onclick='ActiveTable.clearSearchField(\"#{update_element}\",\"#{refresh_url}\",\"#{name}\",\"#{col.header.field_hash}\");' title='#{vh "Clear this search term"}' >#{vh col.header.search_description(searching)}</a>)"
          end
          srch_on = "<input id='#{col.header.field_name}_searching'  type='hidden' name='#{name}[display][#{col.header.field_hash}]' value='#{vh searching ? '1' : '0' }' />"
          srch ? "#{srch_on}<span style='display:none;' id='#{col.header.field_name}_search_for'>#{col.header.name}:#{srch}</span>" : ''
      end

      if existing_search.length > 0
        existing_search = '<b>Searching On:</b>' + existing_search.join(", ")
      else
        existing_search=''
      end
  
      # Create the Search form
      if refresh_url && update_element
       form = "form onsubmit='return ActiveTable.refresh(\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");'"
      else
        form ='form'
      end

      concat("<#{form} id='#{name}_update_form' method='post'>");

      yield(nil) if(form_elements)
      # Initial Tabl Tag     
      concat("<table cellpadding='0' cellspacing='0' #{options.collect { |key,val| "#{key}='#{val}'" }.join(' ')}><input type='hidden' id='#{name}_page' name='page'  value='#{pagination[:page]}'/>")

      # Create the Header Columns in a <thead> section
     concat("<thead><tr>")
      columns.each do |col|
        col.header.active_table = name
        concat(col == columns.first  ? "<th class='first' #{col.header.style} >" : "<th #{col.header.style} >")
        header_txt = col.header.icon ? "<img src='#{theme_src(col.header.icon)}' align='absmiddle' />" : col.header.name.t
        if col.header.is_searchable? && col.header.is_orderable?
          concat("<a href='javascript:void(0);' onclick='ActiveTable.order(\"#{update_element}\",\"#{refresh_url}\",\"#{name}\",\"#{col.header.field_hash}\");'>#{header_txt }</a><a href='javascript:void(0);' onclick='ActiveTable.header(\"#{name}\",\"#{col.header.field_hash}\");'><img src='#{theme_src("/images/icons/find.gif")}' align='absmiddle' width='16' height='16' border='0'/></a>")
        elsif col.header.is_searchable?
          concat("#{header_txt}<a href='javascript:void(0);' onclick='ActiveTable.header(\"#{name}\",\"#{col.header.field_hash}\");'><img src='#{theme_src("/images/icons/find.gif")}' align='absmiddle' width='16' height='16' border='0'/></a>")
        elsif col.header.is_orderable?
          concat("<a href='javascript:void(0);' onclick='ActiveTable.order(\"#{update_element}\",\"#{refresh_url}\",\"#{name}\",\"#{col.header.field_hash}\");'>#{header_txt }</a>")
        else
          concat("#{col.header.name.t}")
        end
        if col.header.is_orderable?
          if col.order == 1
            concat(" - Up")
          elsif col.order == -1
            concat(" - Down")
          end
        end
        
        concat("</th>")
      end 
      
      concat('</tr></thead>')

     
    
      row = options.delete(:row)
      end_row = options.delete(:end_row)
      

      
      
      
      search_str_start = <<EOF
<tbody id='#{name}_search' #{"style='display:none;'" if existing_search.blank?}>
  <tr><td id='#{name}_search_form'  colspan='#{columns.length}'><div class='search_form'>
   <div id='#{name}_search_fields' style='display:none;'>
  #{ '<input type="hidden" name="paction" value="' + paction.to_s + '" />' if paction }
  #{ '<input type="hidden" id="' + name.to_s + '_per_page" name="' + name.to_s + '[per_page]" value="' + pagination[:per_page].to_s + '" />'}

EOF


    search_str_end = <<EOF
   <input type='submit' value='#{"Search".t}' />
   <input type='submit' value='#{"Clear".t}' onclick='return ActiveTable.clearSearch("#{name}","#{refresh_url}","#{update_element}");'/> 
    </div>
    #{existing_search}
    </div>
   </td></tr>
</tbody>
EOF
      
      concat(search_str_start)
      
     
      
      concat("<input type='hidden' id='#{name.to_s}_search_cnt' value='#{search_idx}' />")
          
      concat(search_str.join(' '))
      concat(search_str_end)
      


            
      concat("<tbody>")
      
      if objects.length > 0
        objects.each do |obj|
          concat(row ) if row
          yield obj
          concat(end_row) if end_row
        end 
        concat('</tbody>')
  
  
        if(table_actions || more_actions)
          table_actions_str_start = <<-EOF
          <tbody>
          <tr>
            <td colspan='#{columns.length}'>
              <input type='hidden' name='table_action' id='#{name}_table_action' value=''/>
              <img src='#{theme_src 'icons/check_arrow.gif'}'/><a href='javascript:void(0);' onclick='ActiveTable.checkAll("#{name}",true);'>#{"Check All".t}</a> / 
              <a href='javascript:void(0);' onclick='ActiveTable.checkAll("#{name}",false);'>#{"Uncheck All".t}</a> #{"With Selected:".t} 
          EOF
        
          table_actions_str_end = <<-EOF
            </td>
          </tr>
          </tbody>
          EOF
        
          concat(table_actions_str_start)
          if(table_actions && table_actions.length > 0)
            concat(table_actions.collect { |act|
              if act[1] == 'js'
                "<input type='submit' value='#{vh act[0].t}' onclick='if(ActiveTable.countChecked(\"#{name}\") > 0) { #{jvh act[2]}; } return false;'/>"
              else
                "<input type='submit' value='#{vh act[0].t}' onclick='ActiveTable.action(\"#{act[1]}\",\"#{act[2] ? jvh(act[2]) : ''}\", \"#{name}\", \"#{refresh_url}\",\"#{update_element}\"); return false;'/>"
              end
            }.join(" "))  
          end
  
          if(more_actions && more_actions.length > 0)
            concat("<script>#{name}_more_actions = [")
            concat(more_actions.collect { |act| act[2].blank? ? 'null': "'#{jvh act[2]}'" }.join(","))
            concat(" ]; </script>")
            concat(" <select onchange=' ActiveTable.action(this.value,#{name}_more_actions[this.selectedIndex-1],\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");  this.selectedIndex=0; return false;'><option value=''>#{h '--More Actions--'.t}</option>")
            concat(more_actions.collect { |act|
              "<option value='#{act[1]}' >#{h act[0].t}</option>"
            }.join(""))
  
            concat("</select>")
  
          end
  
          concat(table_actions_str_end)
        end
  
        
        
        
        concat("<tfoot><tr><td colspan='#{columns.length}'><div class='pagination_spacer'></div></td></tr><tr><td class='pagination_row' valign='center' colspan='#{columns.length}' align='right'>")
        concat("<div style='float:left'>#{"Showing".t} <a href='javascript:void(0);' onclick='ActiveTable.windowPopup(#{pagination[:count]},\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");'>#{pagination[:from]}-#{pagination[:to]}</a> #{"Of".t} #{pagination[:count]}</div>")
  
        if pagination[:pages_count] > 1
          concat("<ul class='pagination'>")
          initial = true
          if(pagination[:page] > 1)
            initial = false
            concat( "<li class='first highlight'><a href='javascript:void(0);' onclick='ActiveTable.page(#{pagination[:page]-1},\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");')'>&lt;</a></li>")
          end
          concat(pagination[:pages].collect  {  |number| 
            first = true if initial
            initial = false
            if number.to_i == pagination[:page].to_i 
                "<li class='#{first ? "first " : ""}current'>#{number.to_s}</li>"
            elsif number.is_a?(String)
                "<li class='spacer'>#{number}</li>"
            else
              "<li class='#{first ? "first " :  ""}'><a href='javascript:void(0);' onclick='ActiveTable.page(#{number},\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");')'>#{number}</a></li>"
            end
            
          }.to_s )
          if(pagination[:page] < pagination[:pages_count])
            concat( "<li class='highlight'><a href='javascript:void(0);' onclick='ActiveTable.page(#{pagination[:page]+1},\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");')'>&gt;</a></li>")
          end
          concat('</ul>')
        end
        concat('</td></tr></tfoot>')
      else
        concat("<tbody><tr><td colspan='#{columns.length}'><div align='center'>#{"No Entries".t}</div></td></tr></tbody>")
      end
      concat('</table></form>')
      concat("<script>ActiveTable.checkAll(\"#{name}\",false);</script>")
    end
  
end


