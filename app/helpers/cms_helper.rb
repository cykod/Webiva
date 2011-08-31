# Copyright (C) 2009 Pascal Rettig.


# Helper methods for CmsController derivitive backend controllers
module CmsHelper


  def webiva_search_widget # :nodoc:
    form_tag({ :controller => '/search'},:id => 'search_widget_form', :style => 'display:inline;') +
<<-SEARCH_WIDGET
  <input type='text' name='search' size='20' id='search_widget' value='Search Webiva' />
  
  <div class='autocomplete' id='search_widget_autocomplete' style='display:none; width:500px;'>
     <ul class="autocomplete_list">
       <li class='autocomplete_item' id='result_1'>
         <div class="name">Enter a colon (:) to see registered search handlers</div>
         <div class="subtext">Search handlers let you search different pieces of your Webiva Site</div>
       </li>
       <li class='autocomplete_item' id='result_1'>
         <div class="name">Enter a url to jump to a page of your site</div>
         <div class="subtext">The system will show pages that match the prefix you've entered</div>
       </li>
       <li class='autocomplete_item' id='result_1'>
         <div class="name">Or enter search terms to search content</div>
         <div class="subtext">The system will show site content that matches your search</div>
       </li>
    </ul>
 </div>
 
    <script>
      SearchWidget = {
       onFocus: function() {
          if(this.value=="Search Webiva") this.value=""; 
          SearchWidget.autocomplete.updateChoices($('search_widget_autocomplete').innerHTML);
          SearchWidget.autocomplete.hasFocus = true;
          SearchWidget.autocomplete.changed = false;
          SearchWidget.autocomplete.show();
       },
       onBlur: function() {
         if(this.value=="") this.value="Search Webiva"; 
      },
       setup: function() {
          $('search_widget').onfocus = SearchWidget.onFocus;
          $('search_widget').onblur = SearchWidget.onBlur;

          SearchWidget.autocomplete = new Ajax.Autocompleter('search_widget','search_widget_autocomplete','#{url_for(:controller => '/search', :action => 'autocomplete')}',
        { minChars: 1, frequency: 0.5, paramName: 'search', 
         afterUpdateElement: function(text,li) { 
           var url = li.select(".autocomplete_url");
           var text = li.select(".autocomplete_text");
        if(url[0]) {
           document.location = url[0].value;
          $('search_widget').value = li.select(".name")[0].innerHTML; 
        } else if(text[0]) {
          $('search_widget').value = text[0].value; 
          return false;
        }
        else {
          $('search_widget').value = li.select(".name")[0].innerHTML; 
        }
        },
        onShow: function(element,update) {
        if(!update.style.position || update.style.position=='absolute') {
          update.style.position = 'absolute';
          Position.clone(element, update, {
            setHeight: false,
            setWidth: false,
            offsetTop: element.offsetHeight
          });
          update.style.left = '';
          update.style.right = '0px';
        }
        Effect.Appear(update,{duration:0.15});
       }
      });
      shortcut.add("Alt+S",function() { $('search_widget').focus(); });
  

     }
     };
    

     SearchWidget.setup();
    </script> 
    </form>
SEARCH_WIDGET
  end


  def render_webiva_menu(menu,selected) 
    return '' unless menu
    menu.items.map do |item|
      <<-EOF
      <li #{"class='selected'" if selected == item.identifier }>
          <a href='#{url_for(item.url)}'>
             <div class='menu_image menu_image_#{item.identifier}'><div></div></div>
             <div class='menu_item_text'>#{h(item.name.t)}</div>
          </a>
      </li>
      EOF
    end.join("\n")
  end

  def render_webiva_breadcrumbs(page_info)
    if page_info[:title].is_a?(Array) && page_info[:title].length > 0 
      breadcrumbs = page_info[:title][0..-2]
      breadcrumbs.map do |itm|
        render_webiva_title(itm) + " &gt; "
      end.join
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
    concat("<table class='styled_table admin_form'>")
    cms_subfields_for(name,obj,options,&block)
    concat("</table>")
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
    
      concat("<a href='javascript:void(0);' id='link_#{id}' >" + image_tag(image,options) + "</a>")
      concat("<script type='text/javascript'> $('link_#{id}').onclick = function() { popupMenu('', new Array(")
      
      yield PopupMenuBuilder.new
      
      concat("[] )); }</script>")
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
      concat("<ul class='action_panel' id='action_panel'>")
      
      apb = ActionPanelBuilder.new(self, :directory => 'title_actions')
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
      if options[:more]
        concat(apb.link('more', { :url => 'javascript:void(0);',:icon => 'add.png', :id => 'more_actions_link' },
                        :"j-action" => 'slidetoggle,swap', :swap => '#less_actions_link,#more_actions_link', :slidetoggle => '#more_actions_panel'))

        concat(apb.link('less', { :url => 'javascript:void(0);',:icon => 'remove.png', :id => 'less_actions_link', :hidden => true },
                        :"j-action" => 'slidetoggle,swap', :swap => '#more_actions_link,#less_actions_link', :slidetoggle => '#more_actions_panel'))
      end
      concat("</ul>")
   end   

   def more_action_panel(options = {},&block)
     concat("<div style='display:none;' id='more_actions_panel'>")
     concat("<h2>#{h 'More Actions'.t }<a class='title_link' href=\"javascript:void(0);\" j-action='slideup,swap' swap='#more_actions_link,#less_actions_link' slideup=\"#more_actions_panel\">#{ '(close actions)'.t }</a></h2>")
     concat("<ul>")
      
      apb = ActionPanelBuilder.new(self, :directory => 'actions')
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


      concat('</ul></div>')
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
        right = "class='right'" if opts.delete(:right)
        if link_id= opts.delete(:id)
          id = " id='#{link_id}'" 
        end
        hide = ' style="display:none;"' if opts.delete(:hidden)
        if options[:url]
          opts = options[:url]
        end

        icon =  @ctrl.theme_icon("action","icons/#{@b_opts[:directory]}/" + icon) if icon
        return "<li #{right}#{id}#{hide}>" + @ctrl.send(:link_to,icon.to_s + @ctrl.send(:h,txt),opts,html_options) + "</li>"
      end
      
      # Adds a custom item to the action panel (accepts a block)
      def custom(options = {},&block )
        opts = options.clone
        right = " class='right'" if opts.delete(:right)

        @ctrl.concat("<li#{right}>")
        yield 
        @ctrl.concat("</li>")
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
        @view.concat("<tr #{'style="display:none;"' unless @tab_num  == @selected}><td class='content' colspan='#{@tab_cnt+1}' >")
        @tab_num +=1;
        yield block
        @view.concat("</td></tr>")
      end

      # Creates a tab inside of ajax_tabs and wraps the content of that tab in a table
      # Useful for cms_form_for and tabled_form_for
      def tabled_tab(&block)
        @view.concat("<tr #{'style="display:none;"' unless @tab_num  == @selected}><td class='content' colspan='#{@tab_cnt+1}' ><table>")
        @tab_num +=1;
        yield block
        @view.concat("</table></td></tr>")
      end
      
      # Adds a block that initially appears visible regardless of the selected tab
      # (once a tab is clicked it will act like a normal tab)
      def visible(&block)
        @view.concat("<tr><td class='content' colspan='#{@tab_cnt+2}' >")
        @tab_num +=1;
        yield block
        @view.concat("</tr></td>")
      end
    end
   
   # Same as ajax_tabs except everything is put
   # inside and existing table (useful for tabled_form_for, cms_form_for)
   def tabled_ajax_tabs(options,selected,&block)
    concat("<tr><td colspan='2'>")
    ajax_tabs(options,selected,&block)
    concat("</td></tr>")
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
     concat("<table class='ajax_tabs' cellpadding='0' cellspacing='0'><tr>")
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
     yield AjaxTabBuilder.new(self,options.length,selected_id) if block_given?
     concat("</table>")
   end
   
   class StatViewer # :nodoc:all
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

=begin rdoc   
Used to display a view of data in a formatted manner. 

Usage:

    <% stat_view do |v| %>
      <%= v.header "Header Text" %>
      <%= v.row "Label 1", @object.atr %> <!-- the value will be escaped -->
      <%= v.raw "Label 2", @object.atr2 %> <!-- value not escaped with raw -->
      <%= v.header "Header 2" %>
      ...
    <% end -%>


=end
   def stat_view(options={},&block) # :yields: StatViewer.new
     concat("<table cellspacing='0' cellpadding='0' class='stat_viewer #{options[:class]}'>")
    yield StatViewer.new
    concat("</table>")
   end
   

   # Creates a table give a list of list of objects and list of columns
   # works much like active_table_for - the block is called once for each object
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
  
  # deprecated use active_tr
  def highlight_row(elem_type,elem_id,options={}) # :nodoc:
  
    <<-JAVASCRIPT
    id='elem_#{elem_type}_#{elem_id}_row' onmouseover='SCMS.highlightRow(this);'  onmouseout='SCMS.lowlightRow(this#{ ',"' + jh(options[:clear_callback]) + '"' if options[:clear_callback]});' onclick='SCMS.clickRow("#{elem_type}","#{elem_id}"); #{options[:callback].to_s.gsub("'",'&apos;')}'

    JAVASCRIPT
  end

  # deprecated use active_tr  
  def entry_checkbox(elem_type,elem_id)  # :nodoc:
    <<-JAVASCRIPT
        <input type='checkbox' class='entry_checkbox' name='#{elem_type}[#{elem_id}]' value='#{elem_id}' id='elem_#{elem_type}_#{elem_id}' onclick='this.checked = !this.checked;'  />    
    JAVASCRIPT
  end
  

 class ActiveTableRowBuilder #:nodoc:all
    def initialize(name,entry_id)
      @name = name
      @entry_id =entry_id
    end

    def checkbox
      <<-JAVASCRIPT
        <input type='checkbox' class='entry_checkbox' name='#{@name}[#{@entry_id}]' value='#{@entry_id}' id='elem_#{@name}_#{@entry_id}' onclick='this.checked = !this.checked;'  />    
    JAVASCRIPT
    end
  end
  
  # See ActiveTable 
  # Used to create a highlightable table row inside of an active table
  def active_tr(name,entry_id)
    builder = ActiveTableRowBuilder.new(name,entry_id)
    
    concat("<tr #{highlight_row(name,entry_id)}>")
    yield builder
    concat("</tr>")
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
    output
  end

  # Helper method to render an active_table partial called table name
  # and wrap it in a div
  def active_table_render(table_name)
    "<div id='#{table_name}'>#{render :partial => table_name.to_s}</div>"
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
    concat("<div  #{wrapper_opts.collect { |key,val| "#{key}='#{val}'" }.join(' ')} class='active_table_wrapper'><#{form} id='#{name}_update_form' method='post'>");

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
                     "<input class='button_link' type='submit' value='#{vh act[0].t}' onclick='if(ActiveTable.countChecked(\"#{name}\") > 0) { #{jvh act[2]}; } return false;'/>"
                   else
                     "<input class='button_link' type='submit' value='#{vh act[0].t}' onclick='ActiveTable.action(\"#{act[1]}\",\"#{act[2] ? jvh(act[2]) : ''}\", \"#{name}\", \"#{refresh_url}\",\"#{update_element}\"); return false;'/>"
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
          concat( "<li class='first highlight'><a href='javascript:void(0);' onclick='ActiveTable.page(#{pagination[:page]-1},\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");')'>#{previous_link_text}</a></li>")
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
          concat( "<li class='highlight'><a href='javascript:void(0);' onclick='ActiveTable.page(#{pagination[:page]+1},\"#{name}\",\"#{refresh_url}\",\"#{update_element}\");')'>#{next_link_text}</a></li>")
        end
        concat('</ul>')
      end
      concat('</td></tr></tfoot>')
    else
      concat("<tbody><tr><td colspan='#{columns.length}'><div align='center'>#{"No Entries".t}</div></td></tr></tbody>")
    end
    concat('</table></form></div>')
    concat("<script>ActiveTable.checkAll(\"#{name}\",false);</script>")
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
        help = "<div class='action_icon_mouseover' id='subpage_#{idx}' style='display:none;'><div class='action_icon_mouseover_body'>#{h(pg[4].t)}</div></div>"
        [ icon_html, pg_html, help ]
      else 
        [ '','' ]
      end
    end
    
         
    output +=  html.map { |elm| elm[0] }.join + "</tr><tr>"
    output +=  html.map { |elm| elm[1] }.join + "</tr>"
    output += "</table><div align='center'><div class='action_icon_mouseover' id='subpage_none'><div class='action_icon_mouseover_body'></div></div>"
    output += html.map { |elm| elm[2] }.join + '</div>'
    output
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
        "<#{tag} class='#{css_class}'>#{txt}</#{tag}>"
      elsif number <= @wizard_max_step
        
        "<#{tag}><a href='#{url}'>#{txt}</a></#{tag}>"
      else
        "<#{tag}>#{txt}</#{tag}>"
      end
    end
    
  end
  
  def wizard_steps(wizard_step,wizard_max_step,opts={}) 
    yield WizardSteps.new(wizard_step,wizard_max_step,opts)
  end

  # Load a remote script over http or https as necessary
  def remote_script(script)
    prefix =  request.ssl? ? 'https://' : 'http://'
    "<script src='#{prefix}#{vh script}'></script>"
  end

  # Load a remote stylesheet over http or https as necessary
  def remote_stylesheet(stylesheet)
    prefix =  request.ssl? ? 'https://' : 'http://'
    "<link href='#{prefix}#{vh stylesheet}' rel='stylesheet' type='text/css' />"

  end

  def button_link(icon,text,url,options = {})
    opt = options.clone
    alternative = " button_link_alternative" if opt.delete(:alternative)
    content_tag(:a,image_tag(theme_src('icons/actions/' + icon),:align => 'absmiddle') + text.t,
                options.merge(:class => "button_link#{alternative}", :href => url_for(url)))
  end


 
end
