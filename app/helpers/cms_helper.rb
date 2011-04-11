# Copyright (C) 2009 Pascal Rettig.


# Helper methods for CmsController derivitive backend controllers
module CmsHelper
  def webiva_search_widget # :nodoc:
    render :partial => '/helpers/cms/webiva_search_widget'
  end

  def render_webiva_menu(menu,selected) 
    return '' unless menu
    menu.items.map do |item|
      img = content_tag :div, content_tag(:div, ''), :class => "menu_image menu_image_#{item.identifier}"
      txt = content_tag :div, item.name.t, :class => 'menu_item_text'
      link = content_tag :a, img + txt, :href => url_for(item.url)
      content_tag :li, link, :class => selected == item.identifier ? 'selected' : nil
    end.join("\n").html_safe
  end

  def render_webiva_breadcrumbs(page_info)
    if page_info[:title].is_a?(Array) && page_info[:title].length > 0 
      breadcrumbs = page_info[:title][0..-2]
      breadcrumbs.map do |itm|
        render_webiva_title(itm) + " &gt; ".html_safe
      end.join.html_safe
    else
      nil
    end
  end

  def render_webiva_title(item)
    if item.is_a?(Array) && item[1]
      link_to h( item.length > 2 ? sprintf(item[0].t,*item[2..-1]) : item[0].t), item[1]
    elsif item.is_a?(Array)
      h(sprintf(item[0].t,*item[2..-1])) 
    else
      h item.t
    end
  end

  def member_url(user_id)
    url_for(:controller => '/members',:action => 'view', :path => [user_id])
  end


  # Form for helper that wraps cms_form_for with an admin_form class
  def admin_form_for(name,obj=nil,options={},&block)
    options[:html] ||= {}
    options[:html][:class] = 'admin_form'

    cms_form_for(name,obj,options,&block)
  end
  
  # fields for helper that wraps cms_subfields_for with an admin_form classed table
  def admin_fields_for(name,obj=nil,options={},&block)
    output = "<table class='styled_table admin_form'>"
    output << cms_subfields_for(name,obj,options,&block)
    output << "</table>"
    output.html_safe
  end


  class PopupMenuBuilder #:nodoc:all
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
   
  # Builds a popup menu
  def popup_menu(id,image,options={},&block) # :nodoc:
    options = options.clone
    options[:class] = 'line_icon'
    
    output = content_tag :a, image_tag(image, options), :href => 'javascript:void(0);', :id => "link_#{id}"
    output << "<script type='text/javascript'> $('link_#{id}').onclick = function() { popupMenu('', new Array(".html_safe
      
    output << capture(PopupMenuBuilder.new, &block)
      
    content_tag << "[] )); }</script>".html_safe
  end

=begin rdoc
Creates an action panel (the set of links at the top of an admin page)

Usage :

   <% action_panel do |p| %>
       <%= p.link "Link Description", :action => 'a',:controller => 'c', :icon => 'add.gif' %>
       <%= p.link "Link Description 2", :action => 'a2',:controller => 'c', :icon => 'configure.gif' %>
   <% end -%>

Yields an ActionPanelBuilder. The :icon argument will add an icon next to the image from the
images/icons/actions directory of the current theme. 

=end 
  def action_panel(options = {},&block)  # :yields: ActionPanelBuilder.new
    apb = ActionPanelBuilder.new(self, :directory => 'title_actions')
    content = capture(apb, &block)
      
    if options[:handler]
      handlers = get_handler_info('action_panel',options[:handler])
      
      if handlers
        handlers.each do |handler|
          (handler[:links] || []).each do |link|
            opts = link.clone
            name = opts.delete(:link)
            role = opts.delete(:role)
              
            if !role || myself.has_role?(role)
              content << apb.link(name,opts)
            end
          end
        end
      end
    end

    if options[:more]
      content << apb.link('more', { :url => 'javascript:void(0);',:icon => 'add.png', :id => 'more_actions_link' },
                          :"j-action" => 'slidetoggle,swap', :swap => '#less_actions_link,#more_actions_link', :slidetoggle => '#more_actions_panel')

      content << apb.link('less', { :url => 'javascript:void(0);',:icon => 'remove.png', :id => 'less_actions_link', :hidden => true },
                          :"j-action" => 'slidetoggle,swap', :swap => '#more_actions_link,#less_actions_link', :slidetoggle => '#more_actions_panel')
    end

    content_tag :ul, content, {:class => 'action_panel', :id => 'action_panel'}, false
  end   

   def more_action_panel(options = {},&block)
     apb = ActionPanelBuilder.new(self, :directory => 'actions')
     content = capture(apb, &block)

      if options[:handler]
        handlers = get_handler_info('action_panel',options[:handler])

        if handlers
          handlers.each do |handler|
            (handler[:links] || []).each do |link|
              opts = link.clone
              name = opts.delete(:link)
              role = opts.delete(:role)

              if !role || myself.has_role?(role)
                content << apb.link(name,opts)
              end
            end
          end
        end
      end


     close_link = content_tag :a, '(close actions)', :class => 'title_link', :href => "javascript:void(0);", 'j-action' => 'slideup,swap', :swap => '#more_actions_link,#less_actions_link',  :slideup => "#more_actions_panel"
     more_actions_heading = content_tag :h2, "More Actions #{close_link}", {}, false
     content = content_tag :ul, content, {}, false
     content_tag :div, more_actions_heading + content, {:style => 'display:none', :id => 'more_actions_panel'}, false
   end

   # This class usually isn't instantiated directly, see CmsHelper#action_panel for usage
   class ActionPanelBuilder 
      def initialize(ctrl, options = {}) #:nodoc:
        @ctrl = ctrl
        @b_opts = options
      end
    
      # Creates a link in the action panel
      # Accepts the same arguments as link_to, with a couple of additional options
      # in the first options hash
      #    :right => true  
      #      Float the link to the right
      #    :icon => "filename.gif"
      #      Add an icon next to the image from the theme images/icons/actions directory
      #    :no_translate
      #      Prevents the translation of the link
      def link(txt,options = {},html_options = {})
        opts = options.clone
        icon = opts.delete(:icon)
        txt = txt.t unless opts.delete(:no_translate)
        right = opts.delete(:right)
        hidden = opts.delete(:hidden)
        opts = opts[:url] if opts[:url]
        icon =  @ctrl.theme_icon("action","icons/#{@b_opts[:directory]}/" + icon) if icon
        output = @ctrl.link_to icon.to_s + @ctrl.send(:h, txt), opts, html_options
        @ctrl.content_tag :li, output, {:class => right ? 'right' : nil, :id => options[:id], :style => hidden ? 'display:none;' : nil}, false
      end
      
      # Adds a custom item to the action panel (accepts a block)
      def custom(options = {},&block )
        @ctrl.content_tag :li, @ctrl.capture(&block), {:class => options[:right] ? 'right' : nil}, false
      end
   end
   
  
    # This class usually isn't instantiated directly, see CmsHelper#ajax_tabs for usage
    class AjaxTabBuilder
      include ActionView::Helpers::TextHelper
      def initialize(view,tab_cnt,selected,opts={}) # :nodoc:
        @view = view
        @tab_num = 0
        @selected = selected
        @tab_cnt = tab_cnt
        @opts = opts
      end
      
      # Creates a tab inside of the ajax_tabs
      def tab(&block)
        column = @view.content_tag :td, @view.capture(&block), {:class => 'content', :colspan => @tab_cnt+1}, false
        output = @view.content_tag :tr, column, {:style => @tab_num == @selected ? nil : 'display:none;'}, false
        @tab_num += 1;
        output
      end

      # Creates a tab inside of ajax_tabs and wraps the content of that tab in a table
      # Useful for cms_form_for and tabled_form_for
      def tabled_tab(&block)
        table = @view.content_tag :table, @view.capture(&block), {}, false
        column = @view.content_tag :td, table, {:class => 'content', :colspan => @tab_cnt+1}, false
        output = @view.content_tag :tr, column, {:style => @tab_num == @selected ? nil : 'display:none;'}, false
        @tab_num += 1;
        output 
      end
      
      # Adds a block that initially appears visible regardless of the selected tab
      # (once a tab is clicked it will act like a normal tab)
      def visible(&block)
        column = @view.content_tag :td, @view.capture(&block), {:class => 'content', :colspan => @tab_cnt+2}, false
        @tab_num +=1;
        @view.content_tag :tr, column, {}, false
      end
    end
   
   # Same as ajax_tabs except everything is put
   # inside and existing table (useful for tabled_form_for, cms_form_for)
   def tabled_ajax_tabs(options,selected,&block)
     column = content_tag :td, ajax_tabs(options,selected,&block), {:colspan => 2}, false
     content_tag :tr, column, {}, false
   end
   
=begin rdoc
Creates a set of "Ajax" tabs (Why Ajax? Your guess is as good as mine, and I wrote it)
Basically a set of tabs javascript tabs that don't reload the page when clicked.

Usage:

     <% ajax_tabs ['Tab Name 1','Tab Name 2','Tab Name 3'], 'Tab Name 2'  do |t| %>
        <% t.tab do %>
           Tab 1 content...
        <% end -%>
        <% t.tab do %>
           Tab 2 content...(this will be the initially selected tab)
        <% end -%>
        <% t.tab do %>
           Tab 3 content...
        <% end -%>
     <% end -%> 

The tab options can also be arrays, in which case the system will be attempt to call the 
second element of the option after activating the tab. Useful for situations like:
   
   <% ajax_tabs ['Default Tab',['Tab Name 2','loadExtraData();'], 'Default Tab'  do |t| %>
        <% t.tab do %>
           Tab 1 content...
        <% end -%>
        <% t.tab do %>
           Loading Data Please Wait...
        <% end -%>
   <% end -%>

Where we don't want to have to load data into all the tabs and instead want to make some
Ajax calls to fill them up. Note - the javascript method will be called each time the tab
is clicked, so any sort of preload code will need to do it's own checking to verify that the 
content isn't already loaded.
=end   
   def ajax_tabs(options,selected,&block)   # :yields: ActionTabBuilder.new
     output = "<table class='ajax_tabs' cellpadding='0' cellspacing='0'><tr>"
     selected_id = nil
     options.each_with_index do |opt,idx|
       js= '' 
       if opt.is_a?(Array)
         js = opt[1]
         opt = opt[0]
       end
       selected_id = idx if opt == selected
       
       output << "<td #{opt==selected ? 'class="selected"' : 'class="normal"'}> <a class='ajax_link' onclick='SCMS.select_tab(this); #{js}' href='javascript:void(0);'>#{opt.t}</a></td>"
     end
     output << "<td class='extra'> &nbsp; </td>	</tr>"
     output << capture(AjaxTabBuilder.new(self,options.length,selected_id), &block) if block_given?
     output << "</table>"
     output.html_safe
   end
   
   class StatViewer # :nodoc:all
      include ActionView::Helpers::TagHelper
      
      def initialize
        @headers = 0
      end
    
     def row(label,stat,options = {})
        "<tr><td class='label'  valign='baseline' nowrap='1'>#{h label.t}:</td><td  class='stat' #{"align='#{options[:align]}'" if options[:align]} >#{h stat}</td></tr>".html_safe
     end  
     
     def raw(label,stat,options = {})
        "<tr><td  class='label' valign='baseline' nowrap='1'>#{h label.t}:</td><td  class='stat' #{"align='#{options[:align]}'" if options[:align]}>#{stat}</td></tr>".html_safe
     end
     
     def header(label)
      @headers += 1
      "#{'<tr><td class=\'spacer\' colspan=\'2\'></td></tr>' if @headers > 1}
      <tr><td class='header' colspan='2'><b>#{h label.t}</b></td></tr>".html_safe
     end
   
   end

=begin rdoc   
Used to display a view of data in a formatted manner. 

Usage:

    <%= stat_view do |v| %>
      <%= v.header "Header Text" %>
      <%= v.row "Label 1", @object.atr %> <!-- the value will be escaped -->
      <%= v.raw "Label 2", @object.atr2 %> <!-- value not escaped with raw -->
      <%= v.header "Header 2" %>
      ...
    <% end -%>


=end
   def stat_view(options={},&block) # :yields: StatViewer.new
     content_tag :table, capture(StatViewer.new, &block), {:cellspacing => 0, :cellpadding => 0, :class => "stat_viewer #{options[:class]}"}, false
   end
   

   # Creates a table give a list of list of objects and list of columns
   # works much like active_table_for - the block is called once for each object
  def table_for(objects, columns, options = {}, &block)
    row = options.delete(:row)
    end_row = options.delete(:end_row)
    
    output = "<table cellpadding='0' cellspacing='0' #{options.collect { |key,val| "#{key}='#{h(val)}'" }.join(' ')}><thead><tr>"
    columns.each do |col|
      if col.empty?
        output << "<th class='empty'></th>"
      else
        output << "<th #{"class='first'" if col==columns.first}>#{col.t}</th>"
      end
    end 
    output << '</tr></thead><tbody>'
    
    objects.each do |obj|
      output << row if row
      output << capture(obj, &block)
      output << end_row if end_row
    end 

    output << '</tbody></table>'
    output.html_safe
  end 
  
  # deprecated use active_tr
  def highlight_row(elem_type,elem_id,options={}) # :nodoc:
  
    <<-JAVASCRIPT.html_safe
    id='elem_#{elem_type}_#{elem_id}_row' onmouseover='SCMS.highlightRow(this);'  onmouseout='SCMS.lowlightRow(this#{ ',"' + jh(options[:clear_callback]) + '"' if options[:clear_callback]});' onclick='SCMS.clickRow("#{elem_type}","#{elem_id}"); #{options[:callback].to_s.gsub("'",'&apos;')}'

    JAVASCRIPT
  end

  # deprecated use active_tr  
  def entry_checkbox(elem_type,elem_id)  # :nodoc:
    <<-JAVASCRIPT.html_safe
        <input type='checkbox' class='entry_checkbox' name='#{elem_type}[#{elem_id}]' value='#{elem_id}' id='elem_#{elem_type}_#{elem_id}' onclick='this.checked = !this.checked;'  />    
    JAVASCRIPT
  end
  

 class ActiveTableRowBuilder #:nodoc:all
    def initialize(name,entry_id)
      @name = name
      @entry_id =entry_id
    end

    def checkbox
      <<-JAVASCRIPT.html_safe
        <input type='checkbox' class='entry_checkbox' name='#{@name}[#{@entry_id}]' value='#{@entry_id}' id='elem_#{@name}_#{@entry_id}' onclick='this.checked = !this.checked;'  />    
    JAVASCRIPT
    end
  end
  
  # See ActiveTable 
  # Used to create a highlightable table row inside of an active table
  def active_tr(name, entry_id, &block)
    builder = ActiveTableRowBuilder.new(name,entry_id)
    
    output = "<tr #{highlight_row(name,entry_id)}>"
    output << capture(builder, &block)
    output << "</tr>"
    output.html_safe
  end


  # Generate pagination_links like those used by active_table
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
    output.html_safe
  end

  # Helper method to render an active_table partial called table name
  # and wrap it in a div
  def active_table_render(table_name)
    "<div id='#{table_name}'>#{render :partial => table_name.to_s}</div>".html_safe
  end
  
=begin rdoc
Outputs an active table
See ActiveTable for usage examples

=== Options
  [:actions]
    An array of options where each element follows the following pattern:
    [ "Display Name","action_name","Optional confirmation popup questions?" ]
    These will appear at the bottom of the table and can be parsed by using the
    active_table_action controller method
  [:more_actions]
    These operate the same as [:actions] except they will appear in the drop down,
    should be used for less common (or more destructive) actions
  [:class]
     Class of the table tag - defaults to active_table
  [:form_elements]
     Set this to true if you would like active table to yield once without an object
     so that extra form elements can be added into the active_table_form
  [:refresh_url]
     The url to update the table at. Defaults to display_[name]
  [:update]
     The name of the element to update, defaults to [name]
=end
  def active_table_for(name,active_table_output,options={},&block)
    options = options.symbolize_keys

    pagination = active_table_output.paging
    objects = active_table_output.data
    columns = active_table_output.column_instances

    table_actions = options.delete(:actions)
    more_actions = options.delete(:more_actions)

    next_link_text = options.delete(:next) || '&gt;'
    previous_link_text = options.delete(:previous) || '&lt;'

    options[:class] ||= "active_table"

    form_elements = options.delete(:form_elements)
    
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

    wrapper_opts = { }
    wrapper_opts[:style] = "display:block;" if options[:width]
    output = "<div  #{wrapper_opts.collect { |key,val| "#{key}='#{val}'" }.join(' ')} class='active_table_wrapper'><#{form} id='#{name}_update_form' method='post'>"

    output << capture(nil, &block) if(form_elements)
    # Initial Tabl Tag     
    output << "<table cellpadding='0' cellspacing='0' #{options.collect { |key,val| "#{key}='#{val}'" }.join(' ')}><input type='hidden' id='#{name}_page' name='page'  value='#{pagination[:page]}'/>"

    # Create the Header Columns in a <thead> section
    output << "<thead><tr>"
    columns.each do |col|
      col.header.active_table = name
      output << ((col == columns.first) ? "<th class='first' #{col.header.style} >" : "<th #{col.header.style} >")
      header_txt = col.header.icon ? "<img src='#{theme_src(col.header.icon)}' align='absmiddle' />" : col.header.name.t
      if col.header.is_searchable? && col.header.is_orderable?
        output << "<a href='javascript:void(0);' onclick='ActiveTable.order(\"#{update_element}\",\"#{refresh_url}\",\"#{name}\",\"#{col.header.field_hash}\");'>#{header_txt }</a><a href='javascript:void(0);' onclick='ActiveTable.header(\"#{name}\",\"#{col.header.field_hash}\");'><img src='#{theme_src("/images/icons/find.gif")}' align='absmiddle' width='16' height='16' border='0'/></a>"
      elsif col.header.is_searchable?
        output << "#{header_txt}<a href='javascript:void(0);' onclick='ActiveTable.header(\"#{name}\",\"#{col.header.field_hash}\");'><img src='#{theme_src("/images/icons/find.gif")}' align='absmiddle' width='16' height='16' border='0'/></a>"
      elsif col.header.is_orderable?
        output << "<a href='javascript:void(0);' onclick='ActiveTable.order(\"#{update_element}\",\"#{refresh_url}\",\"#{name}\",\"#{col.header.field_hash}\");'>#{header_txt }</a>"
      else
        output << "#{col.header.name.t}"
      end
      if col.header.is_orderable?
        if col.order == 1
          output << " - Up"
        elsif col.order == -1
          output << " - Down"
        end
      end
      
      output << "</th>"
    end 
    
    output << '</tr></thead>'

    
    
    row = options.delete(:row)
    end_row = options.delete(:end_row)
    

    
    
    
    search_str_start = <<EOF
<tbody id='#{name}_search' #{"style='display:none;'" if existing_search.blank?}>
  <tr><td id='#{name}_search_form'  colspan='#{columns.length}'><div class='search_form'>
   <div id='#{name}_search_fields' style='display:none;'>
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
    
    output << search_str_start
    
    
    
    output << "<input type='hidden' id='#{name.to_s}_search_cnt' value='#{search_idx}' />"
    
    output << search_str.join(' ')
    output << search_str_end
    


    
    output << "<tbody>"
    
    if objects.length > 0
      objects.each do |obj|
        output << row if row
        output << capture(obj, &block)
        output << end_row if end_row
      end 
      output << '</tbody>'
      
      
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
        
        output << table_actions_str_start
        if(table_actions && table_actions.length > 0)
          output << table_actions.collect { |act|
                   if act[1] == 'js'
                     "<input class='button_link' type='submit' value='#{vh act[0].t}' onclick='if(ActiveTable.countChecked(\"#{name}\") > 0) { #{jvh act[2]}; } return false;'/>"
                   else
                     "<input class='button_link' type='submit' value='#{vh act[0].t}' onclick='ActiveTable.action(\"#{act[1]}\",\"#{act[2] ? jvh(act[2]) : ''}\", \"#{name}\", \"#{refresh_url}\",\"#{update_element}\"); return false;'/>"
                   end
                 }.join(" ")
        end
        
        if(more_actions && more_actions.length > 0)
          output << "<script>#{name}_more_actions = ["
          output << more_actions.collect { |act| act[2].blank? ? 'null': "'#{jvh act[2]}'" }.join(",")
          output << " ]; </script>"
          output << " <select onchange=' ActiveTable.action(this.value,#{name}_more_actions[this.selectedIndex-1],\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");  this.selectedIndex=0; return false;'><option value=''>#{h '--More Actions--'.t}</option>"
          output << more_actions.collect { |act|
                   "<option value='#{act[1]}' >#{h act[0].t}</option>"
                 }.join("")
          
          output << "</select>"
          
        end
        
        output << table_actions_str_end
      end
      
      
      
      
      output << "<tfoot><tr><td colspan='#{columns.length}'><div class='pagination_spacer'></div></td></tr><tr><td class='pagination_row' valign='center' colspan='#{columns.length}' align='right'>"
      output << "<div style='float:left'>#{"Showing".t} <a href='javascript:void(0);' onclick='ActiveTable.windowPopup(#{pagination[:count]},\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");'>#{pagination[:from]}-#{pagination[:to]}</a> #{"Of".t} #{pagination[:count]}</div>"
      
      if pagination[:pages_count] > 1
        output << "<ul class='pagination'>"
        initial = true
        if(pagination[:page] > 1)
          initial = false
          output <<  "<li class='first highlight'><a href='javascript:void(0);' onclick='ActiveTable.page(#{pagination[:page]-1},\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");')'>#{previous_link_text}</a></li>"
        end
        output << pagination[:pages].collect  {  |number| 
                 first = true if initial
                 initial = false
                 if number.to_i == pagination[:page].to_i 
                   "<li class='#{first ? "first " : ""}current'>#{number.to_s}</li>"
                 elsif number.is_a?(String)
                   "<li class='spacer'>#{number}</li>"
                 else
                   "<li class='#{first ? "first " :  ""}'><a href='javascript:void(0);' onclick='ActiveTable.page(#{number},\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");')'>#{number}</a></li>"
                 end
                 
               }.to_s
        if(pagination[:page] < pagination[:pages_count])
          output << "<li class='highlight'><a href='javascript:void(0);' onclick='ActiveTable.page(#{pagination[:page]+1},\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");')'>#{next_link_text}</a></li>"
        end
        output << '</ul>'
      end
      output << '</td></tr></tfoot>'
    else
      output << "<tbody><tr><td colspan='#{columns.length}'><div align='center'>#{"No Entries".t}</div></td></tr></tbody>"
    end
    output << '</table></form></div>'
    output << "<script>ActiveTable.checkAll(\"#{name}\",false);</script>"
    output.html_safe
  end

  # Display a list of subpages in a management controller,
  # adding an additional pages that match the name
  # see app/views/options/index.rhtml and OptionsController#index for an example
 def subpage_display(name,pages)
    output = "<table align='center' class='action_icon_table'><tr>"
    
    idx = -1
    
    pages = pages.clone
    handlers = get_handler_info(:navigation,name)
  
    (handlers||[]).each do |handler|
      pages += handler[:pages] if handler[:pages].is_a?(Array)
    end
      
    
    
    html = pages.collect do |pg|
      idx += 1
      if myself.has_role?(pg[1].to_s)
        icon_html = <<-OUTPUT
          <td class='icon'><a href='#{url_for pg[3]}' j-action='toggler' toggler="#subpage_#{idx},#subpage_none">#{theme_image_tag "actions/" + pg[2]}</a></td>
        OUTPUT
        pg_html = <<-OUTPUT
          <td class='txt'><a href='#{url_for pg[3]}'  j-action='toggler' toggler="#subpage_#{idx},#subpage_none">#{pg[0].t.gsub("\n","<br/>")}</a></td>
        OUTPUT
        help = "<div class='action_icon_mouseover' id='subpage_#{idx}' style='display:none;'><div class='action_icon_mouseover_body'>#{h(pg[4])}</div></div>"
        [ icon_html, pg_html, help ]
      else 
        [ '','' ]
      end
    end
    
         
    output +=  html.map { |elm| elm[0] }.join + "</tr><tr>"
    output +=  html.map { |elm| elm[1] }.join + "</tr>"
    output += "</table><div align='center'><div class='action_icon_mouseover' id='subpage_none'><div class='action_icon_mouseover_body'></div></div>"
    output += html.map { |elm| elm[2] }.join + '</div>'
    output.html_safe
  end

  class WizardSteps
    def initialize(wizard_step,wizard_max_step,opts={}) 
      @wizard_step = wizard_step
      @wizard_max_step = wizard_max_step
      @options = opts
    end
    
    def step(number,txt,url = {})
    
      tag = @options[:tag] || 'span'
      css_class = @options[:class] || 'large_ajax_link_selected'
      if number == @wizard_step
        "<#{tag} class='#{css_class}'>#{txt}</#{tag}>".html_safe
      elsif number <= @wizard_max_step
        "<#{tag}><a href='#{url}'>#{txt}</a></#{tag}>".html_safe
      else
        "<#{tag}>#{txt}</#{tag}>".html_safe
      end
    end
    
  end
  
  def wizard_steps(wizard_step,wizard_max_step,opts={}, &block) 
    capture WizardSteps.new(wizard_step,wizard_max_step,opts), &block
  end

  # Load a remote script over http or https as necessary
  def remote_script(script)
    prefix =  request.ssl? ? 'https://' : 'http://'
    "<script src='#{prefix}#{vh script}'></script>".html_safe
  end

  # Load a remote stylesheet over http or https as necessary
  def remote_stylesheet(stylesheet)
    prefix =  request.ssl? ? 'https://' : 'http://'
    "<link href='#{prefix}#{vh stylesheet}' rel='stylesheet' type='text/css' />".html_safe

  end

  def button_link(icon,text,url,options = {})
    opt = options.clone
    alternative = " button_link_alternative" if opt.delete(:alternative)
    content_tag(:a,image_tag(theme_src('icons/actions/' + icon),:align => 'absmiddle') + text.t,
                options.merge(:class => "button_link#{alternative}", :href => url_for(url)))
  end
end
