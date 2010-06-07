# Copyright (C) 2009 Pascal Rettig.



class EndUserTable 
    
  include EscapeHelper

  def initialize(renderer,name,mdl,columns,options={})
    @renderer = renderer
    @name = name
    @mdl = mdl
    @columns = columns
    @options = options
  end
  
  attr_reader :renderer, :name, :options, :columns, :mdl, :page_connection_hash
  attr_writer :page_connection_hash
  
  
  module Controller  
    include ActionView::Helpers::TextHelper
    #2.0 include ActionView::Helpers::PaginationHelper

    def end_user_table(table_name,table_model,table_columns)
        require_js('prototype')
        require_js('user_application')
        require_js('end_user_table')
        require_css('end_user_table')
        EndUserTable.new(self, table_name,table_model,table_columns,params)
    end

    def end_user_table_action(tbl)
     if(request.post? && !params[:end_user_table_action].blank? && params[tbl.name.to_s + "_row"].is_a?(Hash)) 
      yield params[:end_user_table_action],params[tbl.name.to_s + "_row"].values
     end
   end
   
    def end_user_table_generate(tbl,find_options = {})
 
        table_name = tbl.name.to_sym
        model_class = tbl.mdl
        opts = params[table_name] ||  {}
        
        find_options = find_options.clone || {}
        session[:end_user_table] ||= {}
        session[:end_user_table][table_name] ||= {}
        order = session[:end_user_table][table_name][:order]
        
        if opts[:order]
          if order == opts[:order]
            order = opts[:order] + ' DESC'
          else
            order = opts[:order]
          end
        end
        
        if opts
          search_options = opts.clone
          search_options.stringify_keys!
          session[:end_user_table][table_name] = search_options.to_hash
          
        elsif session[:end_user_table] && session[:end_user_table][table_name]
          search_options = session[:end_user_table][table_name]
          search_options.stringify_keys!
        else
          search_options = {}
        end
        
                
        search_display = search_options['display'] || {}
        
        session[:end_user_table][table_name][:order] = order
        
        found_order = false

        column_instances = tbl.columns.collect do |hdr|
          ordering = nil
          if hdr.field == order && hdr.sortable?
            ordering = 1 
            found_order = true
          elsif hdr.field + " DESC" == order  && hdr.sortable?
           ordering = -1
            found_order = true
          else
            ordering = nil
          end
          
          ColumnInstance.new(tbl,hdr,
                             search_display[hdr.field].to_i == 1 && hdr.is_searching?(search_options[hdr.field])  ? search_options[hdr.field] : nil,
                             ordering )
        end

        if found_order && ( order && order != '1' && order != '1 DESC')
          if find_options[:order]
            find_options[:order] = order + ', ' + find_options[:order]
          else
            find_options[:order] = order
          end
        end 


        if find_options[:conditions] && find_options[:conditions].is_a?(Array)
          find_options[:conditions] = find_options[:conditions]
        else 
          find_options[:conditions] = [ find_options[:conditions] || '1' ]
        end
        
        column_instances.each do |col|
          conditions = col.search_conditions
          if conditions && conditions.length > 0
            sql = conditions.shift
            find_options[:conditions][0] += ' AND ' + sql
            find_options[:conditions] += conditions if conditions.length > 0
          end
          joins = col.search_joins
          if joins
            find_options[:joins] ||= []
            find_options[:joins] << joins
          end
          
        end
        
        select_count = find_options.delete(:select_count) 

        find_per_page = find_options.delete(:per_page) 
        
        per_page = (search_options['per_page'] ||  find_per_page || 10).to_i
        window_size = find_options.delete(:window_size) || 4
        
        count_by = find_options.delete(:count_by) || :id
        
        count_options = find_options.clone
        count_options.delete(:group)
        count_options.delete(:select)
        count_options.delete(:order)
#        count_options.delete(:joins)
        count_options[:distinct] = true
        

        if(tbl.options[:count_callback]) 
          entry_count = self.send(options[:count_callback],count_options)
        else
          entry_count = model_class.count(count_by,count_options)
        end
        #count_options[:select] = "COUNT(DISTINCT #{count_by}) as cnt" 
        #entry_count = model_class.find(:first,count_by,count_options)
        #entry_count = entry_count.cnt
        
        page = (opts.delete(:page) || 1).to_i
        pages_count = (entry_count.to_f / per_page).ceil.to_i
        pages_count = 1 if pages_count < 1
        
        if(page < 1)
          page = 1
        elsif page > pages_count
          page = pages_count
        end
        
        
        
        find_options[:offset] = (page-1) * per_page
        find_options[:limit] = per_page

        # Find out the first page to show
        start_page = (page - window_size - 1) > 1 ? (page - window_size - 1) : 1
        end_page = (start_page + (window_size*2) + 1)
        if end_page > pages_count - 1
          start_page -= end_page - pages_count 
          start_page = 1 if start_page < 1 
          end_page = pages_count
        end
        
        pages = (start_page..end_page).to_a

        if start_page == 1
          pages
        elsif start_page == 2
          pages = [ 1 ] +  pages
        elsif start_page > 2
          pages = [ 1, '..' ] +  pages[1..-1]
        end
        
        if end_page == pages_count
          pages
        elsif end_page == pages_count
          pages << pages_count 
        elsif end_page < pages_count
          pages += [ '..', pages_count ]
        end
        
        from_entry = find_options[:offset] + 1
        to_entry = find_options[:offset] + per_page
        to_entry = entry_count if(to_entry > entry_count)        
        tbl.page_connection_hash = page_connection_hash
        tbl.set_meta_data({ :page => page, :pages => pages, :pages_count => pages_count, :per_page => per_page, :count => entry_count, :from => from_entry, :to => to_entry  })
        tbl.data = tbl.options[:find_callback] ? self.send(tbl.options[:find_callback],find_options) : model_class.find(:all,find_options)
    end
  end
    
  
  def generated?
    @data ? true : false
  end

  attr_accessor :data
  attr_reader :meta_data
  
  def set_meta_data(meta_data)
    @meta_data = meta_data
  end
  ## HTML Generation
  
  
  def header_html
    output = "<tr>"
    @columns.each do |col|
      if col.sortable?
        align=col.options[:align] ? "align='#{col.options[:align]}'" : ''
        wid=col.options[:width] ? "width='#{col.options[:width]}'" : ''
        output += <<-JAVASCRIPT
          <th valign='bottom' #{align} #{wid} ><a href='?#{@name}[order]=#{col.field}' onclick='EndUserTable.order("#{@name}","#{col.field}"); return false;'>#{col.label}</a></th>
        JAVASCRIPT
      else
        output += "<th>#{col.label}</th>"
      end
    end
    
    output += "</tr>"
    output
  end
  
  
  def footer_html(table_type='table')
        pagination = self.meta_data
        if(table_type=='table')
          output = "<tfoot><tr><td colspan='#{columns.length}'><div class='pagination_spacer'></div></td></tr><tr><td class='pagination_row' valign='center' colspan='#{columns.length}' align='right'>"
        else
          output = "<div class='pagination_row'>"
        end
        
        if self.data.length > 0
          output += "<div style='float:left'>#{"Showing".t} #{pagination[:from]}-#{pagination[:to]} #{"Of".t} #{pagination[:count]}</div>"
    
          if pagination[:pages_count] > 1
            output += "<ul class='pagination'>"
            initial = true
            if(pagination[:page] > 1)
              initial = false
              output +=  "<li class='first highlight'><a href='javascript:void(0);' onclick='EndUserTable.page(\"#{name}\",#{pagination[:page]-1});')'>&lt;</a></li>"
            end
            output += pagination[:pages].collect  {  |number| 
              first = true if initial
              initial = false
              if number.to_i == pagination[:page].to_i 
                  "<li class='#{first ? "first " : ""}current'>#{number.to_s}</li>"
              elsif number.is_a?(String)
                  "<li class='spacer'>#{number}</li>"
              else
                "<li class='#{first ? "first " :  ""}'><a href='javascript:void(0);' onclick='EndUserTable.page(\"#{name}\",#{number});'>#{number}</a></li>"
              end
              
            }.to_s 
            if(pagination[:page] < pagination[:pages_count])
              output +=  "<li class='highlight'><a href='javascript:void(0);' onclick='EndUserTable.page(\"#{name}\",#{pagination[:page]+1});')'>&gt;</a></li>"
            end
            output += '</ul>'
          end
        end
        
        if(table_type=='table')
          output += '</td></tr></tfoot>'  
        else
          output += "</div>"
        end
        
        output
  end
  
  def highlight_row(elem,options = {})
    elem_id = elem.id
    elem_type = @name.to_s + "_row"
    <<-JAVASCRIPT
    id='elem_#{elem_type}_#{elem_id}_row' onmouseover='SCMS.highlightRow(this);'  onmouseout='SCMS.lowlightRow(this#{ ',"' + jh(options[:clear_callback]) + '"' if options[:clear_callback]});' onclick='SCMS.clickRow("#{elem_type}","#{elem_id}"); #{options[:callback].to_s.gsub("'",'&apos;')}'

    JAVASCRIPT
  end
  
  def entry_checkbox(elem,options = {}) 
    elem_id = elem.id
    elem_type = @name.to_s + "_row"
    <<-JAVASCRIPT
        <input type='checkbox' class='entry_checkbox' name='#{elem_type}[#{elem_id}]' value='#{elem_id}' id='elem_#{elem_type}_#{elem_id}' onclick='this.checked = !this.checked;'  />    
    JAVASCRIPT
  end
  
  
  class ColumnInstance  #:nodoc:all
    attr_reader :active_table
    attr_reader :header
    attr_reader :searching
    attr_reader :order
    
    def initialize(tbl,header,searching,order)
      @tbl = tbl
      @header =header
      @searching = searching if searching && searching != ''
      @order = order
    end
    
    def search_conditions
      (searching && @header.search_type == 'conditions') ? @header.search_conditions(searching) : nil
    end

    def search_joins
      (searching && @header.search_type == 'join') ? @header.search_join(searching) : nil
    end
    
    def search_html
      @header.search_html(@tbl,searching)
    end
    
    
  end  

  class TableColumn #:nodoc:all
  
    def initialize(field,opts={})
      @field = field
      @options = opts
      
      @name = @options.delete(:label)
      if !@name
        @name = field.to_s.split(".")[-1].to_s.humanize
      end
      @icon = @options.delete(:icon)
    end
    
    attr_reader :field, :name, :options
    
    def label; @name; end
    def style; @width ? "style='width:#{@width}px;'" : ''; end
    def field_name; _s + '_' + @field.to_s; end
    
    def search_html(active_table,searching = nil); nil; end
    def search_conditions(searching=nil); nil; end 
    def search_description(searching=''); ''; end

    def is_searching?(searching = nil); !searching.blank?; end

    def sortable?; true; end
    def searchable?; true; end
    def search_type; 'conditions'; end

    def options_callback; nil;  end

    def search_join(searching=nil); nil; end 
  end

  class StringColumn < TableColumn #:nodoc:all
  end
  
  class NumberColumn < TableColumn #:nodoc:all
  end
   
  class OrderHeader < TableColumn #:nodoc:all
    def searchable?; false; end
  end
  
  class StaticHeader < TableColumn #:nodoc:all
    def sortable?; false; end
    def searchable?; false; end
  end
  
  class BlankHeader < TableColumn #:nodoc:all
    def initialize(opts={},dummy=nil)
      opts = {} unless opts.is_a?(Hash)
      super('',opts)
    end
    def sortable?; false; end
    def searchable?; false; end
  end
  
  
  @@column_types = { :string => StringColumn, :number => NumberColumn, :static => StaticHeader, :blank => BlankHeader, :order => OrderHeader }
  
  def self.column(col_type,name='',opts = {})
    @@column_types[col_type.to_sym].new(name,opts)
  end

end
