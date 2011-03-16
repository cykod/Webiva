# Copyright (C) 2009 Pascal Rettig.

module PageHelper


  def webiva_javascript_tags(js_includes,js_header)
    if js_includes || js_header
      if js_header; js_includes ||= []; js_includes += js_header; end 

      js_includes.uniq.each do |js|
        if js.to_s[0..3] == 'http'
          concat(" <script src=\"#{vh js}\" type='text/javascript'></script>\n")
        else 
          concat(" " + javascript_include_tag(js) + "\n")
        end
      end
    end
    nil
  end

  def webiva_css_tags(css_includes,css_header)
    if css_includes || css_header
      if css_header; css_includes ||= []; css_includes += css_header; end 
      css_includes.uniq.each do |css|
        concat(" " + stylesheet_link_tag(css, :media => 'all') + "\n")
      end
    end
    nil
  end


  def ajax_url_for(rnd,options={})
    opts = options.merge(:site_node => rnd.paragraph.page_revision ? rnd.paragraph.page_revision.revision_container_id : 0, 
                         :page_revision => rnd.paragraph.page_revision_id,
                         :paragraph => rnd.paragraph.id)
    rnd.paragraph_action_url(opts)
  end
  
  def end_user_table_for(tbl,options = {},&block)
   options = options.clone
   options.symbolize_keys!
   if options[:style]
    style ="style='#{options[:style]}'"
   else
    style = ''
   end
   tbl_type =options[:type] == 'div' ? 'div' : 'table'

   if options[:class]
     extra_class = " " + options[:class]
   end
   
   div_id = options[:container_id] || "cmspara_#{tbl.renderer.paragraph.id}"
   concat(register_table_js(tbl,div_id,options[:refresh_url]))
   concat("<form id='#{tbl.name}_update_form' action='' onsubmit='return false;'>") unless options[:no_form]
   concat("<input type='hidden' name='page_connection_hash' value='#{tbl.page_connection_hash}' />") unless options[:no_form]
   
   if tbl_type == 'table'
      concat("<#{tbl_type} cellspacing='0' cellpadding='0' class='user_#{tbl_type}#{extra_class}' #{style} >")
   else
     concat("<#{tbl_type} class='user_#{tbl_type}#{extra_class}' #{style} >")
   end
   
   
    unless options[:no_header] || tbl_type == 'div'
     concat(tbl.header_html)
    end
   
    if !tbl.generated?
      raise 'Table not generated!'
    end
    concat("<tbody>") if tbl_type == 'table'
    if tbl.data.length > 0
      tbl.data.each do |row|
        yield row
      end
    else
      concat("<tr><td colspan='#{tbl.columns.length}' align='center'>#{options[:empty]}</td></tr>") if options[:empty]
    end
    concat("</tbody>") if tbl_type == 'table'
    
    table_actions = options.delete(:actions)
    more_actions = options.delete(:more_actions)
    table_name = tbl.name
    
    
     if tbl.data.length > 0 && (table_actions || more_actions) && tbl_type =='table'
      table_actions_str_start = <<-EOF
      <tbody>
      <tr>
        <td colspan='#{tbl.columns.length}'>
          <input type='hidden' name='end_user_table_action' id='#{table_name}_table_action' value=''/>
          <img src='#{theme_src 'icons/check_arrow.gif'}'/><a href='javascript:void(0);' onclick='EndUserTable.checkAll("#{table_name}",true);'>#{"Check All".t}</a> / 
          <a href='javascript:void(0);' onclick='EndUserTable.checkAll("#{table_name}",false);'>#{"Uncheck All".t}</a> #{"With Selected:".t} 
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
            "<input type='submit' value='#{vh act[0].t}' onclick='if(EndUserTable.countChecked(\"#{table_name}\") > 0) { #{jvh act[2]}; } return false;'/>"
          else
            "<input type='submit' value='#{vh act[0].t}' onclick='EndUserTable.action(\"#{table_name}\",\"#{act[1]}\",\"#{act[2] ? jvh(act[2]) : ''}\"); return false;'/>"
          end
        }.join(" "))  
      end

      if(more_actions && more_actions.length > 0)
        concat("<script>#{table_name}_more_actions = [")
        concat(more_actions.collect { |act| act[2].blank? ? 'null': "'#{jvh act[2]}'" }.join(","))
        concat(" ]; </script>")
        concat(" <select onchange=' EndUserTable.action(\"#{table_name}\",this.value,#{table_name}_more_actions[this.selectedIndex-1]);  this.selectedIndex=0; return false;'><option value=''>#{h '--More Actions--'.t}</option>")
        concat(more_actions.collect { |act|
          "<option value='#{act[1]}' >#{h act[0].t}</option>"
        }.join(""))

        concat("</select>")

      end

      concat(table_actions_str_end)
    end
    unless options[:no_pages] || tbl_type =='div'
      concat(tbl.footer_html(tbl_type))
    end
    
   concat("</#{tbl_type}>")
    unless options[:no_pages] || tbl_type =='table'
      concat(tbl.footer_html(tbl_type))
    end
   concat("</form>") unless options[:no_form]
   
  
    
  end
  
  def register_table_js(tbl,div_id,refresh_url=nil)
    <<-JAVASCRIPT
      <script type='text/javascript'>
          try { EndUserTable.registerTable("#{tbl.name}","#{refresh_url || ajax_url_for(tbl.renderer,:update_table => tbl.name)}","#{div_id}"); } 
          catch(err) { }
      </script>
    JAVASCRIPT
  end
  
  def rating_widget(rating,options = {})
    stars = options[:stars] || 5
    unselected_icon = options[:icon] || theme_src('icons/star_unselected.gif')
    selected_icon = options[:selected] || theme_src('icons/star_selected.gif')
    count = options[:count] || 1
    if rating && count.to_i > 0
      rating = rating.to_f / count.to_i
      rating_str = sprintf("%0.1f/%d",rating,stars)
    else
      rating = 0.0
      rating_str = 'No rating'.t
    end
    rating_str += options[:text] if options[:text]
    (1..stars).collect do |star|
      if star <= rating
        "<img src='#{selected_icon}' align='absmiddle' title='#{rating_str}'/>"
      else
        "<img src='#{unselected_icon}' align='absmiddle' title='#{rating_str}'/>"
      end   
    end.join
  end
  
  def active_rating_widget(rating,options = {})
    stars = options[:stars] || 5
    unselected_icon = options[:icon] || theme_src('icons/star_unselected.gif')
    selected_icon = options[:selected] || theme_src('icons/star_selected.gif')
    count = options[:count] || 1
    elem_id = options[:id] || 'rating'
    
    if rating && count.to_i > 0
      rating = rating.to_f / count.to_i
    else
      rating = 0.0
    end
    star_html = (1..stars).collect do |star|
        "<a href='javascript:void(0);' onclick='#{elem_id}Rating.clickStar(#{star});' onmouseover='#{elem_id}Rating.highlightStar(#{star});'  onmouseout='#{elem_id}Rating.resetStar(#{star});' ><img src='#{star <= rating ?
selected_icon : unselected_icon}' id='#{elem_id}#{star}' align='absmiddle' title='#{star}/#{stars}'/></a>"
    end.join
    star_js = <<-JAVASCRIPT
    <script>
      document.#{elem_id}Rating = { 
        unselected: '#{unselected_icon}',
        selected: '#{selected_icon}',
        rating: #{rating},
        setStar: function(val) {
          for(var i=1;i<=#{stars};i++) {
              $("#{elem_id}" + i).src = ( i <= val ? this.selected : this.unselected );
          }
        },
        
        highlightStar: function(num) {
          this.setStar(num);
        },
        
        resetStar: function(num) {
          this.setStar(this.rating);
        },
        
        clickStar: function(num) {
          this.rating = num;
          this.setStar(num);
          #{options[:callback]}num);
        }
      };

    </script>
    JAVASCRIPT
    
    return star_js + star_html
    
  end

  def content_node_links(objects)
    return nil unless objects
    objects.map do |obj| 
      nd = ContentNode.find_by_id(obj)
      if nd && admin_url = nd.admin_url 
        admin_url.symbolize_keys!
        if myself.has_content_permission?(admin_url.delete(:permission))
          name = admin_url.delete(:title) || nd.node_type.underscore.titleize
          url = url_for(admin_url) + "?return_to_site=true"
          (link_to h(name), url)
        else
          nil
        end
      end
    end.compact.join("<br/>") + "<br/><br/>"
  end
  
end
