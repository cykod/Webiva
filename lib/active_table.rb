# Copyright (C) 2009 Pascal Rettig.
require "digest"


=begin rdoc
ActiveTable is a module that adds in "active" AJAX-updatable and searchable tables into the sytem. 

It defines a number of different ActiveTable::ColumnHeader classes which represent different types of 
columns that can be ordered and or searched and will auto-generate the SQL for those conditions.

When the columns and order of the columns is known ahead of time (as it normally is), you can
use the #active_table singleton method to define the table and then generate the output for the 
table by calling (table_name)_generate 

Headers are generally created using the hdr(type,field, options = {}) method but to keep the header 
definition succinct the system will also try to autogenerate the appropriate header for 
string and date fields if you just pass in a symbol with the column name it will create a header

=== Example usage

 class UserController < CmsController

   ...

   # Define a table called user_table on the EndUser model
   active_table :user_table, EndUser,
         [ :check,                    # used for the initial check_box column
           :first_name,               # creates a string header
           hdr(:string,:last_name),   # explicitly create a string header
           hdr(:boolean,:registered), # create a boolean header
           :registered_at,            # automatically create a :date_range header
           hdr(:options,:source,      # explicitly create an options header
               :options => [ ['Website','website']... ]),
           "Tags",                    # implicitly create a static header
           hdr(:static,"Actions")]    # Explicitly Create a static header

   # Ajax method
   def display_user_table(display=true)

     active_table_action('user') do |act,user_ids|
       case act
       when 'delete': EndUser.destroy(user_ids)
       when ...do something else...
       end
     end

     @tbl = user_table_generate params, 
        :conditions => [ 'active=1' ],
        :order => 'last_name, first_name'

     render :partial => 'user_table' if display
   end

   # Full page method
   def index
     
     display_user_table(false)
   end

   ...

  end

index.erb.html

  ...

  <div id='user_table'><%= render :partial => 'user_table' %></div>

_user_table.erb.html

  <% active_table_for :user_table, @tbl,
     :actions => [['Delete','delete','Are you sure you want to delete these users?']] do |t| -%>
   <% active_tr 'user', t.id do |tr| %>
    <td><%= tr.checkbox %></td>
    <td><%= h t.first_name %></td>
    ...
   <% end -%>
  <% end -%>


#active_table_for defaults to updating a div with the same name as the table, but that can be overridden 
with the [:update] option. It will default to call a controller method called display_[table_name] but 
can be overridden with the :refresh_url option. :more_actions will display a list of additional actions that
will appear in a drop down to the right of :actions. 

=== Header options 
[:label]
  Will use this instead of the humanized field name as a label
[:options]
  Either an select-friendly array of options [[name,id],...] or a symbol that maps to a instance
  method that returns a select-friendly array of options
[:width] 
  A width in pixels for the header column to display
[:icon]
  An icon image to display in-front of the label (except the icon header, which uses this instead of a field name)

=== Header Types
[:blank]
  Create an empty header used for filler columns
[:boolean]
  Create a header appropriate for boolean fields - orderable and searchable
[:date]
  Create a header with an orderable and searchable date (however date_range is often a better choice)
[:date_range]
  Create a header that lets the user enter a range of dates to display
[:exists]
  Used for columns to determine whether they are null or not 
[:has_relation]
  Used for belongs_to fields, checks if the value is > 0 or not > 0, useful for foreign keys
[:icon]
  Header that isn't sortable or searchable but displays and icon image
[:multi_option_header]
  Uses a LIKE search to searches for multiple options in a serialized area in a text field (used by the content system)
[:number_header]
  Used to search on an integer
[:join_header]
  Advanced header that searches for available options doing a join with some custom join sql. Pass an :options argument to 
  the options has for the searchable values (or pass a symbol to use a callback)
[:option_header]
  Header that searches among available options. Pass an :options argument to 
  the options has for the searchable values (or pass a symbol to use a callback)
[:order_header]
  Header is is only orderable and not searchable
[:static_header]
  Header that is neither orderable nor searchable
[:string_header]
  Header that is orderable and allows a LIKE search on the contents of the value
[:two_string_header]
  Header that does a like search on two fields. Pass :second_field as an option to the options hash
=end
module ActiveTable 

  # Methods available in controllers related to ActiveTable
  module Controller 
    include ActionView::Helpers::TextHelper
    #2.0 include ActionView::Helpers::PaginationHelper


    # Controller helper method to handle actions on entries in the table
    def active_table_action(entry_type) # :yields: action_name, entry_id_array
     if(request.post? && params[:table_action] && params[entry_type.to_sym].is_a?(Hash)) 
      yield params[:table_action],params[entry_type.to_sym].values
     end
   end

    # Method that returns the ordering field
    # This method is called with [:table_name]_order when the active_table singleton method is used
    def active_table_order(table_name,columns,opts)
      session[:active_table] ||= {}
      session[:active_table][table_name.to_sym] ||= {}
      order = session[:active_table][table_name.to_sym][:order]
      if opts[:order]
        if order == opts[:order]
          order = opts[:order] + ' DESC'
        else
          order = opts[:order]
        end
      end

      session[:active_table][table_name.to_sym][:order] = order

      columns.each do |hdr|
        if hdr.field_hash == order && hdr.is_orderable?
          return hdr.field
        elsif hdr.field_hash + " DESC" == order  && hdr.is_orderable?
          return hdr.field + " DESC"
        end
      end

      nil
    end

    def active_table_set_order(table_name,columns,order)
      session[:active_table] ||= {}
      session[:active_table][table_name.to_sym] ||= {}
      session[:active_table][table_name.to_sym][:order] = nil

      columns.each do |hdr|
        next unless hdr.is_orderable?

        if hdr.field == order
          session[:active_table][table_name.to_sym][:order] = hdr.field_hash
          return
        elsif hdr.field + " DESC" == order
          session[:active_table][table_name.to_sym][:order] = hdr.field_hash + " DESC"
          return
        end
      end
    end

    # Method that actually generates the data for the table, only called directly in the 
    # case of a non-classes level tables.
    # This method is called with [:table_name]_generate when the active_table singleton method is used
    def active_table_generate(table_name,model_class,columns,options,opts,find_options = {})
 
        opts ||= {}
        
        find_options = find_options.clone || {}
        session[:active_table] ||= {}
        session[:active_table][table_name.to_sym] ||= {}
        order = session[:active_table][table_name.to_sym][:order]
        if opts[:order]
          if order == opts[:order]
            order = opts[:order] + ' DESC'
          else
            order = opts[:order]
          end
        end
        
        if opts[table_name]
          search_options = opts[table_name]
          search_options.stringify_keys!
          session[:active_table] ||= {}
          session[:active_table][table_name.to_sym] = search_options.to_hash

          
        elsif session[:active_table] && session[:active_table][table_name.to_sym]
          search_options = session[:active_table][table_name.to_sym]
          search_options.stringify_keys!
        else
          search_options = {}
        end
        search_display = search_options['display'] || {}
        
        session[:active_table][table_name.to_sym][:order] = order
        
        ordering_field = nil

        column_instances = columns.collect do |hdr|
          ordering = nil
          if hdr.field_hash == order && hdr.is_orderable?
            ordering = 1 
            ordering_field = hdr.field
          elsif hdr.field_hash + " DESC" == order  && hdr.is_orderable?
           ordering = -1
            ordering_field = hdr.field + " DESC"
          else
            ordering = nil
          end
          if hdr.options_callback
            hdr.available_options = self.send(hdr.options_callback)
          end
      
          
          ColumnInstance.new(table_name,
                             hdr,
                             search_display[hdr.field_hash].to_i == 1 && hdr.is_searching?(search_options[hdr.field_hash])  ? search_options[hdr.field_hash] : nil,
                             ordering )
        end

        if ordering_field && ( order && order != '1' && order != '1 DESC')
          if find_options[:order]
            find_options[:order] = ordering_field + ', ' + find_options[:order]
          else
            find_options[:order] = ordering_field
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
        show_all = find_options.delete(:all)

        per_page = (search_options['per_page'] ||  find_per_page || 10).to_i
        window_size = find_options.delete(:window_size) || 4
        
        count_by = find_options.delete(:count_by) || (model_class.table_name + '.id')
        
        count_options = find_options.clone
        count_options.delete(:group)
        count_options.delete(:select)
        count_options.delete(:order)
#        count_options.delete(:include)
        count_options[:distinct] = true
        

        if(options[:count_callback]) 
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
        find_options[:limit] = per_page unless show_all

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
        
        if end_page < pages_count
          pages += [ '..', pages_count ]
        end
        
        from_entry = find_options[:offset] + 1
        to_entry = find_options[:offset] + per_page
        to_entry = entry_count if(to_entry > entry_count)        

        paging = { :page => page, :pages => pages, :pages_count => pages_count, :per_page => per_page, :count => entry_count, :from => from_entry, :to => to_entry  }
        ActiveTable::TableOutput.new(
            options[:find_callback] ? self.send(options[:find_callback],find_options) : model_class.find(:all,find_options),
            paging,
            column_instances)
    end

    
    def Controller.append_features(mod )  # :nodoc: 
      super
      mod.extend ActiveTable::ClassFunctions
    end
    
  
  end
  
  
  # Singleton methods included available in controllers
  module ClassFunctions

    # Helper method for creating active_table headers. Can also 
    # Create the classes directly
     def hdr(type,*opts)
      begin
        type = :option if type.to_s == 'options'
        cls = "ActiveTable::#{type.to_s.camelcase}Header".constantize
        opts[0] = opts[0].to_s
        cls.new(*opts)
      rescue Exception => e
        raise "Invalid ActiveTable Header:" + type.to_s + "ActiveTable::#{type.to_s.classify}Header" + e.to_s
      end
    end

     # Helper method to generate an active table.
     # table_name should be a symbol, model_class should be an 
     # DomainModel class and columns should be an array of 
     # symbols, hashes and ActiveTable::ColumnHeader columns created via the #hdr method
    def active_table(table_name,model_class,columns,options = {})
    
      columns = columns.collect do |col|
        if col.is_a?(Symbol)
          col_name = col.to_s
          if col_name =~ /^(.*)\_(on|at)$/
            hdr(:date_range,"`#{model_class.table_name}`.`#{col_name}`",:label => $1.humanize)
          elsif col_name == 'check'
            hdr(:icon,'',:width => 16)
          elsif col_name == 'blank'
            hdr(:blank)
          elsif col_name == 'end_user'
            hdr(:two_string,'end_users.first_name',:second_field => 'end_users.last_name',:label => 'User')
          else
            hdr(:string,"`#{model_class.table_name}`.`#{col_name}`", :label => col_name.humanize)
          end
        elsif col.is_a?(String)
          hdr(:static,col)
        else
         col
        end
      end
      
      define_method "#{table_name}_generate" do |opts,*find_options|
        active_table_generate(table_name,model_class,columns,options,opts,*find_options)
      end

      define_method "#{table_name}_order" do |opts|
        active_table_order(table_name,columns,opts)
      end

      define_method "#{table_name}_set_order" do |order|
        active_table_set_order(table_name,columns,order)
      end
      
      define_method "#{table_name}_columns" do 
        columns
      end
      
    end
    
    


    
  end
  
  # Object generated by active_table_generate
  class TableOutput #:nodoc: all
    attr_reader :data,:paging,:column_instances
    
    def initialize(data,paging,column_instances)
      @data = data
      @paging = paging
      @column_instances = column_instances
    end
  end
  
  # ActiveTable generates ColumnInstance's representing actual instances of a ColumnHeader,
  # which reference the header but include additional searching and order state
  class ColumnInstance  #:nodoc: all
    attr_reader :active_table
    attr_reader :header
    attr_reader :searching
    attr_reader :order
    
    def initialize(active_table,header,searching,order) #:nodoc:
      @active_table = active_table
      @header =header
      @searching = searching if searching && searching != ''
      @order = order
    end
    
    def search_conditions #:nodoc:
      (searching && @header.search_type == 'conditions') ? @header.search_conditions(searching) : nil
    end

    def search_joins #:nodoc:
      (searching && @header.search_type == 'join') ? @header.search_join(searching) : nil
    end
    
    def search_html #:nodoc:
      @header.search_html(@active_table,searching)
    end
    
    
  end
  

  # Parent class representing a header of the table, subclass this to define new
  # header types. See active_table.rb for example of existing headers
  class ColumnHeader 
    attr_reader :field
    attr_reader :name
    attr_reader :icon
    attr_accessor :active_table
    attr_accessor :options
    attr_accessor :available_options
  
    def initialize(field,options = {})
      @field = field
      @name = options.delete(:label)
      if !@name
        @name = field.to_s.split(".")[-1].to_s.humanize
      end
      @icon = options.delete(:icon)
      @width = options.delete(:width)
      @options = options
    end
    

    def style
      @width ? "style='width:#{@width}px;'" : ''
    end
    
    def field_hash
      @field_hash ||= Digest::SHA1.hexdigest(@field.to_s)
    end

    def field_name
      #@active_table.to_s + '_' + @field.to_s
      @active_table.to_s + '_' + field_hash
    end
    
    def search_html(active_table,searching = nil)
      nil
    end
    
    def search_conditions(searching=nil)
      nil
    end 

    def search_description(searching='')
      ''
    end
    
    def dummy_search 
      'Dummy'
    end

    def is_searching?(searching = nil)
      !searching.blank?
    end

    def is_searchable?
      true # searchable by default
    end
    
    def is_orderable?
      true # orderable by default
    end

    # Join or Conditions
    def search_type
      'conditions' 
    end

    def options_callback
      nil
    end

    def search_join(searching=nil)
      nil
    end 
    
  end
  
  class OptionHeader < ColumnHeader # :nodoc: all
  
    def initialize(field,options = {})
      @available_options = options.delete(:options)
      if @available_options.is_a?(Symbol)
        @options_callback = @available_options
        @available_options = nil
      end
      @display = options.delete(:display) || 'checkbox'
      
      @noun = options.delete(:noun) || ''
      super
    end

   def options_callback
     @options_callback ? @options_callback : nil
    end

  
    def search_html(active_table,searching = nil)
      if @display == 'checkbox'
        html = []
        
        @available_options.each_with_index do |opt,i|
          html << "<label ondblclick='ActiveTable.checkOne(\"#{field_name}\",#{i});' for='#{field_name}_#{i}'><input type='checkbox' ondblclick='ActiveTable.checkOne(\"#{field_name}\",#{i});' #{ "checked='checked'" unless searching && !searching.include?(opt[1].to_s) } id='#{field_name}_#{i}' name='#{active_table}[#{field_hash}][]' value='#{opt[1]}'/>#{opt[0].t}</label>"
        end
        html.join("&nbsp;")
      else
        default_opt = searching.blank? || (searching.is_a?(Array) && searching[0].blank?)
        html = "<select name='#{active_table}[#{field_hash}]' ><option value='' #{"selected='selected'" if default_opt } >#{@noun ? ('--Select ' + @noun.t + '--') : '--Select--'.t}</option>"
        @available_options.each_with_index do |opt,i|
          html += "<option value='#{opt[1]}' #{"selected=' selected'" unless !searching || !searching.include?(opt[1].to_s) }  >#{opt[0]}</option>"
        end
        html += '</select>'
      end

    end 

    def search_description(searching = '')
      searching = [searching] unless searching.is_a?(Array)

      @available_options.find_all() { |itm| searching.include?(itm[1].to_s) }.collect { |itm| itm[0] }.join(", ")
    end
    
    def search_conditions(searching = nil)
      searching = [searching] unless searching.is_a?(Array)
      srch_txt = []
      srch_vals = []
      searching.each do |srch|
        srch_txt << '?'
        srch_vals << srch
      end
      
      [ " #{field} IN (#{srch_txt.join(',')}) " ] + srch_vals
    end

    def is_orderable?
      true # orderable by default
    end

  end
  
  class MultiOptionHeader < OptionHeader # :nodoc: all
  
    def search_conditions(searching = nil)
      searching = [searching] unless searching.is_a?(Array)
      srch_txt = []
      srch_vals = []
      searching.each do |srch|
        srch_txt << "#{field} LIKE ?"
        srch_vals << "%- #{srch}%\n"
      end
      
      [ " ( #{srch_txt.join(" OR ")} ) " ] + srch_vals
    end
  end

  class JoinHeader < ColumnHeader # :nodoc: all

    def initialize(field,join_sql,options = {})
      @join_sql = join_sql
      @available_options = options.delete(:options)
      @options_callback = @available_options if @available_options.is_a?(Symbol)
      @display = options.delete(:display) || 'checkbox'
      super(field,options)
    end

   def search_html(active_table,searching = nil)
      
      if @display == 'checkbox'
        html = []
        @available_options.each_with_index do |opt,i|
          html << "<label ondblclick='ActiveTable.checkOne(\"#{field_name}\",#{i});' for='#{field_name}_#{i}'><input type='checkbox' ondblclick='ActiveTable.checkOne(\"#{field_name}\",#{i});' #{ "checked='checked'" unless searching && !searching.include?(opt[1].to_s) } id='#{field_name}_#{i}' name='#{active_table}[#{field_hash}][]' value='#{opt[1]}'/>#{opt[0].t}</label>"
        end
        html.join("&nbsp;")
      else
        default_opt = searching.blank? || (searching.is_a?(Array) && searching[0].blank?)
        html = "<select name='#{active_table}[#{field_hash}]' ><option value='' #{"selected='selected'" if default_opt } >#{'--Select--'.t}</option>"
        @available_options.each_with_index do |opt,i|
          html += "<option value='#{opt[1]}' #{"selected=' selected'" unless !searching || !searching.include?(opt[1].to_s) }  >#{opt[0]}</option>"
        end
        html += '</select>'
      end
    end 
    
    def dummy_search 
      [ 'Dummy' ]
    end
  

    def search_description(searching = '')
      searching = [searching] unless searching.is_a?(Array)

      @available_options.find_all() { |itm| searching.include?(itm[1].to_s) }.collect { |itm| itm[0] }.join(", ")
    end

    def options_callback
     @options_callback ? @options_callback : nil
    end

    def search_type
      'join'
    end

    def search_join(searching = nil)
      searching = [ searching ] unless searching.is_a?(Array)
      
      @join_sql.sub('?',searching.collect { |srch| DomainModel.connection.quote(srch.to_s) }.join(',') )
    end

    def is_orderable?
      false # orderable by default
    end

  end
  
  class DateHeader < ColumnHeader # :nodoc: all

   def initialize(field,options = {})
      @datetime_field = options.delete(:datetime)
      super(field,options)
    end
    
    def dummy_search 
      '1/1/2008'
    end
    

    def search_html(active_table,searching=nil)
      date_txt = searching
      url = '/website/public/calendar' 
      <<-SRC
        <input name='#{active_table}[#{field_hash}]' id="#{field_name}" value="#{date_txt}" size="15" />
        <a href='javascript:void(0);'
          onclick='if(!$("#{field_name}").disabled) SCMS.pickerWindow("#{url}",{date: $("#{field_name}").value, callback:"#{field_name}"}, {width: 250, height: 180 })' id='#{field_name}_date'>
          <img src='/images/calendar.gif' width='16' height='16' align='absmiddle' border='0'/>
          </a>
      SRC
    end

    def search_conditions(searching = nil)
      val = Time.parse_date(searching).strftime("%Y-%m-%d")
      if @datetime_field
        [ "#{field} >= ? && #{field} <= ? ",val + ' 00:00:00', val + ' 23:59:59' ] 
      else
        [ "#{field} = ? ",val] 
      end
      
    end

    def search_description(searching = '')
      if searching.is_a?(Time)
       searching.strftime('%d/%m/%Y'.t)
      else
        searching
      end
    end
    
  end
  
  class DateRangeHeader < ColumnHeader # :nodoc: all

   def initialize(field,options = {})
      @datetime_field = options.delete(:datetime)
      super(field,options)
    end

    def search_html(active_table,searching=nil)
      date_txt = searching.is_a?(Hash) ? searching : {}
      url = '/website/public/calendar' 
      <<-SRC
        After:<input name='#{active_table}[#{field_hash}][start]' id="#{field_name}_start" value="#{date_txt['start']}" size="15" />
        <a href='javascript:void(0);'
          onclick='if(!$("#{field_name}_start").disabled) SCMS.pickerWindow("#{url}",{date: $("#{field_name}_start").value, callback:"#{field_name}_start"}, {width: 250, height: 180 })' id='#{field_name}_date_start'>
          <img src='/images/calendar.gif' width='16' height='16' align='absmiddle' border='0'/>
          </a>
        Before:<input name='#{active_table}[#{field_hash}][end]' id="#{field_name}_end" value="#{date_txt['end']}" size="15" />
        <a href='javascript:void(0);'
          onclick='if(!$("#{field_name}_end").disabled) SCMS.pickerWindow("#{url}",{date: $("#{field_name}_end").value, callback:"#{field_name}_end"}, {width: 250, height: 180 })' id='#{field_name}_date_end'>
          <img src='/images/calendar.gif' width='16' height='16' align='absmiddle' border='0'/>
          </a>
      SRC
    end

    def dummy_search
      { :start => '1/1/2008', :end => '1/1/2009'  }
    end

    def is_searching?(searching = nil)
      return !searching['start'].blank? || !searching['end'].blank? 
    end

    def search_conditions(searching = nil)
      if searching.is_a?(Hash)
        conds = [ [] ]
        unless searching['start'].blank?
          begin
            val_start = Time.parse_date(searching['start']).strftime("%Y-%m-%d")
            conds[0] << "#{field} >= ?"
            conds << val_start + (@datetime_field ? ' 00:00:00' : '')
          rescue ArgumentError  
            true
          end
        end
        unless searching['end'].blank?
          begin
            val_end = Time.parse_date(searching['end']).strftime("%Y-%m-%d")
            conds[0] << "#{field} <= ?"
            conds <<  val_end + (@datetime_field ? ' 00:00:00' : '') 
          rescue ArgumentError
            true
          end
        end
        return nil unless conds.length > 1
        conds[0] = conds[0].join(" AND ")
        conds
      else
        nil
      end
      
    end

    def search_description(searching = '')
      if searching.is_a?(Time)
       searching.strftime('%d/%m/%Y'.t)
      elsif searching.is_a?(Hash)
        val_start = nil
        val_end = nil
        begin
          val_start = Time.parse_date(searching['start'])
        rescue ArgumentError 
          true
        end

        begin
          val_end = Time.parse_date(searching['end'])
        rescue ArgumentError 
          true
        end


        if val_end
          if val_start
            sprintf("Between %s and %s".t,searching['start'],searching['end'])
          else
            sprintf("Before %s".t,searching['end'])
          end
        elsif val_start
            sprintf("After %s".t,searching['start'])
        else
          'Invalid Dates'.t
        end
      else
        ''
      end
    end
    
  end
  
  class StringHeader < ColumnHeader # :nodoc: all
    def search_html(active_table,searching)
      "<input type='string' id='#{field_name}' name='#{active_table}[#{field_hash}]' size='30' value='#{searching}' />"
    end

    def search_description(searching = '')
        searching
    end
    
    def search_conditions(searching)
      [ "#{field} LIKE ? ",'%' + searching + '%'] if searching && searching != ''
    end
  end

  class TwoStringHeader < ColumnHeader # :nodoc: all
    def search_html(active_table,searching)
      "<input type='string' id='#{field_name}' name='#{active_table}[#{field_hash}]' size='30' value='#{searching}' />"
    end

    def search_description(searching = '')
        searching
    end
    
    def search_conditions(searching)
      [ "(#{field} LIKE ? OR #{@options[:second_field]} LIKE ?) ",'%' + searching + '%','%' + searching + '%'] if searching && searching != ''
    end
  end

  class NumberHeader < ColumnHeader # :nodoc: all
    def search_html(active_table,searching)
      "<input type='string' name='#{active_table}[#{field_hash}]' size='30' value='#{searching}' />"
    end

    def search_description(searching = '')
        searching
    end
    
    def dummy_search
      "12"
    end
    
    def search_conditions(searching)
      [ "#{field} = ? ",searching] if searching && searching != ''
    end
  end

  class ExistsHeader < ColumnHeader # :nodoc: all
    def search_html(active_table,searching)
      "<label for='#{field_name}_yes'> <input type='radio' id='#{field_name}_yes' name='#{active_table}[#{field_hash}]' value='1'  #{"checked='checked'" if searching == "1"}> Yes</label><label  for='#{field_name}_no'> <input type='radio' no='#{field_name}_no' #{"checked='checked'" if searching == "0"}  name='#{active_table}[#{field_hash}]' value='0'> No</label>" 
    end

    def is_orderable?
      false
    end

    def search_description(searching = '')
        searching == '1' ? "Yes".t : "No".t 
    end
    
    def dummy_search
      "1"
    end
    
    def search_conditions(searching)
      if searching == '1'
        [ "#{field} IS NOT NULL "]
      else
        [ "#{field} IS NULL "]
      end
    end
  end
  
  class HasRelationHeader < ColumnHeader # :nodoc: all
    def search_html(active_table,searching)
      "<label for='#{field_name}_yes'> <input type='radio' id='#{field_name}_yes' name='#{active_table}[#{field_hash}]' value='1'  #{"checked='checked'" if searching == "1"}> Yes</label><label  for='#{field_name}_no'> <input type='radio' no='#{field_name}_no' #{"checked='checked'" if searching == "0"}  name='#{active_table}[#{field_hash}]' value='0'> No</label>" 
    end

    def is_orderable?
      false
    end

    def search_description(searching = '')
        searching == '1' ? "Yes".t : "No".t 
    end
    
    def dummy_search
      "1"
    end
    
    def search_conditions(searching)
      if searching == '1'
        [ "#{field} > 0 "]
      else
        [ "NOT (#{field} > 0)  "]
      end
    end
  end
    
  
  class BooleanHeader < ColumnHeader  # :nodoc: all
    def search_html(active_table,searching)
      "<label for='#{field_name}_yes'> <input type='radio' id='#{field_name}_yes' name='#{active_table}[#{field_hash}]' value='1'  #{"checked='checked'" if searching == "1"}> Yes</label><label  for='#{field_name}_no'> <input type='radio' no='#{field_name}_no' #{"checked='checked'" if searching == "0"}  name='#{active_table}[#{field_hash}]' value='0'> No</label>" 
    end

    def is_orderable?
      true
    end
    
    def dummy_search
      "1"
    end
    

    def search_description(searching = '')
        searching == '1' ? "Yes".t : "No".t 
    end
    
    def search_conditions(searching)
      if searching == '1'
        [ "#{field} = 1"]
      else
        [ "#{field} = 0 "]
      end
    end
  
  end

  class OrderHeader < ColumnHeader # :nodoc: all
    def is_searchable?
      false # turn off searching on order headers
    end
  end
  
  class StaticHeader < ColumnHeader # :nodoc: all
    def is_searchable?
      false # turn off searching on order headers
    end
    
    def is_orderable?
      false # turn off searching on order headers
    end
  end
  
  class BlankHeader < StaticHeader # :nodoc: all
    def initialize
      super('')
    end
  end

  class IconHeader < StaticHeader  # :nodoc: all
    def initialize(icon,options={})
      @icon = icon
      super('',options)
    end
  end

end
