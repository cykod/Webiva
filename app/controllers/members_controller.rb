# Copyright (C) 2009 Pascal Rettig.

class MembersController < CmsController # :nodoc: all

  permit 'editor_members', :except => [:lookup_autocomplete]

  layout 'manage'
  
  cms_admin_paths "people",
                  "People" => { :controller => '/members' },
                  "User Lists" => { :action => 'segments' }
  
  # need to include 
  include ActiveTable::Controller   
  include MembersHelper

  protected 

  def segmentations
    return @segmentations if @segmentations
    @segmentations = UserSegment.find(:all, :conditions => {:main_page => true, :status => 'finished'}, :order => 'name')
    @segmentations << self.segment if self.segment && ! @segmentations.find { |seg| seg.id == self.segment.id }
    @segmentations
  end

  def segment
    @segment ||= UserSegment.find_by_id(params[:path][0]) if params[:path]
  end

  def count_end_users(opts)
    if self.search_results
      self.search.total
    elsif self.segment
      self.segment.last_count
    else
      EndUser.count :conditions => 'client_user_id IS NULL'
    end
  end

  def find_end_users(opts={})
    if self.search_results
      self.search.users
    elsif self.segment
      pages, users = self.segment.paginate self.search.page, :per_page => opts[:limit] || 10, :include => opts[:include]
      users
    else
      EndUser.find(:all, :conditions => 'client_user_id IS NULL', :offset => opts[:offset], :limit => opts[:limit], :order => self.class.module_options.order(opts), :include => opts[:include])
    end
  end

  def search
    return @search if @search

    @search = EndUserSearch.new
    @search.terms = params[:terms]
    @search.per_page = 25
    @search.offset = (params[:offset] || 0).to_i
    @search.offsets = (params[:offsets] || [0]).collect { |n| n.to_i }
    @search.user_segment = self.segment
    @search.page = (params[:page] || 1).to_i
    @search.offset = @search.offsets[@search.page-1] if @search.user_segment && @search.offsets.length >= @search.page
    @search
  end

  def search_results
    @search_results ||= self.search.search(:include => [:user_class, :domain_file]) if self.search.terms
  end

  def get_user_classes
    UserClass.find(:all,:order => 'name',:conditions => 'editor=0 AND id>3').collect { |cls| [cls.name,cls.id] }
  end

  def handle_table_actions
    active_table_action('user') do |act,uids| 
      uids = uids.map(&:to_i)
      if act == 'delete'
        EndUser.destroy(uids)
      else
        update_users = EndUser.find(:all,:conditions => { :id => uids })
        
        case act
        when 'acknowledge'
          update_users.map { |usr| usr.update_attribute(:acknowledged,true) }
        when 'add_tags'
          update_users.each do |user|
            user.tag_names_add(params[:added_tags]) if user
          end
        when 'remove_tags'
          update_users.each do |user|
            user.tag_remove(params[:removed_tags], :separator => ',') if user
          end
        when 'clear_tags'
          update_users.each do |user|
            user.clear_tags! if user
          end
        when 'add_users'
          custom_segment = UserSegment.find params[:user_segment_id]
          custom_segment.add_ids uids if custom_segment && custom_segment.segment_type == 'custom'
        when 'remove_users'
          custom_segment = UserSegment.find params[:path][0]
          custom_segment.remove_ids(uids) if custom_segment && custom_segment.segment_type == 'custom'
        when 'quick_edit'
          quick_edit_fields = [ :referrer,:user_class_id,:user_level,:source,:lead_source ]
          fields = params[:edit].slice(*quick_edit_fields)
          quick_edit_fields.each { |fld| fields.delete(fld) if fields[fld].blank? }
          update_vip = params[:edit][:vip]
          update_users.each do |usr|
            usr.vip_number = EndUser.generate_vip if update_vip
            usr.update_attributes(fields)
          end
        end
      end
    end
  end
  
  def email_targets_table_columns(opts={})
    return @email_targets_table_columns if @email_targets_table_columns

    @email_targets_table_columns = [
      ActiveTable::IconHeader.new('check', :width => '16'),
      ActiveTable::OrderHeader.new('user_level',:label => 'Lvl', :width => '24'),
      ActiveTable::StaticHeader.new('Edit', :width => '24'),
      ActiveTable::StaticHeader.new('Image', :width => '70'),
      ActiveTable::StaticHeader.new('Name'),
      ActiveTable::OrderHeader.new('email')
    ]

    @fields = []
    end_user_only = true
    if self.segment && self.segment.fields
      @fields = self.segment.fields.length > 0 ? self.segment.fields : self.class.module_options.fields
      end_user_only = false
    else self.class.module_options && self.class.module_options.fields
      @fields = self.class.module_options.fields
      end_user_only = true
    end

    @fields.each do |field|
      info = UserSegment::FieldHandler.display_fields[field.to_sym]
      if info
        if UserSegment::FieldHandler.sortable_fields(:end_user_only => end_user_only)[field.to_sym]
          @email_targets_table_columns << ActiveTable::OrderHeader.new(field, :label => info[:handler].field_heading(field.to_sym))
        else
          @email_targets_table_columns << ActiveTable::StaticHeader.new(field, :label => info[:handler].field_heading(field.to_sym))
        end
      end
    end

    @email_targets_table_columns
  end

  def email_targets_table_name
    if self.segment
      "end_users_segment_#{self.segment.id}"
    else
      'end_users'
    end
  end

  def email_targets_table_generate(opts,*find_options)
    active_table_generate(self.email_targets_table_name, EndUser, self.email_targets_table_columns, {:count_callback => 'count_end_users', :find_callback => 'find_end_users'}, opts, *find_options)
  end

  def email_targets_table_order(opts)
    active_table_order(self.email_targets_table_name, self.email_targets_table_columns, opts)
  end

  def email_targets_table_set_order(order)
    active_table_set_order(self.email_targets_table_name, self.email_targets_table_columns, order)
  end

  def user_segment_type_select_options
    UserSegment.segment_type_select_options
  end

  def user_segment_status_select_options
    UserSegment.status_select_options
  end

  public 
  
  def lookup_autocomplete
    return render :nothing => true if params[:member].blank?

    name = params[:member].split(" ").collect { |elm| elm.strip }.find_all { |elm| !elm.blank? }
    @users = []
    if(!name.blank?)
      @users = EndUser.find(:all,:conditions => [' membership_id = ?',params[:member].to_s.strip ])
    end
    if @users.length == 0  && name.length > 0
      if(name.length == 1)
        name = "%" + name[0].downcase + "%"
        @conditions = [ 'last_name LIKE ? OR first_name LIKE ?',name,name ]
      else
        if name[0][-1..-1] == "," # Handle rettig, pascal
          name = [name[1],name[0][0..-2]]
        end
        @conditions = [ 'first_name LIKE ? AND last_name LIKE ?',"%" + name[0].downcase + "%","%" + name[1].downcase + "%" ]
      end
      @users = EndUser.find(:all,:conditions => @conditions, :order => 'last_name, first_name')
    end
    render :partial => 'lookup_autocomplete'
  end
  
  def display_targets_table(display = true)

    if params[:table_action] || params[:segment_action]
      handle_table_actions
    end

    params[email_targets_table_name] = params[:email_targets_table]
    @active_table_output = email_targets_table_generate params, :include => [:user_class, :domain_file]

    @handlers_data = UserSegment.get_handlers_data(@active_table_output.data(&:id), @fields)

    if display
      @update_tags = true

      if @update_segments
        segmentations
      end
      render :partial => 'targets_table'
    end
  end
  
  # Members editing
  def index
    return redirect_to(:action => 'segments') if self.segment && ! self.segment.ready?

    cms_page_path ["People"], self.segment ? self.segment.name : 'Everyone'.t

    segmentations

    display_targets_table(false)


  end

   active_table :user_segments_table,
                UserSegment,
                [ hdr(:icon, 'check', :width => '16'),
                  hdr(:icon, '', :width => '32'),
                  :name,
                  :main_page,
                  hdr(:options, :segment_type, :options => :user_segment_type_select_options),
                  :description,
                  hdr(:options, :status, :options => :user_segment_status_select_options),
                  :last_count,
                  :last_ran_at,
                  :created_at,
                  :updated_at
                ]

  def user_segments_table(display=true)
    active_table_action 'user_segments' do |act,ids|
      case act
      when 'delete': UserSegment.destroy(ids)
      when 'add'
        UserSegment.update_all('main_page = 1', :id => ids)
      when 'remove'
        UserSegment.update_all('main_page = 0', :id => ids)
      when 'duplicate'
        ids.each { |id| UserSegment.create_copy id }
      end
    end

    @active_table_output = user_segments_table_generate params, :order => 'updated_at DESC'
    render :partial => 'user_segments_table' if display
  end

  def options
    cms_page_path ['People'], "Everyone Options"
    
    @options = self.class.module_options(params[:options])

    if request.post? && @options.valid?
      if params[:commit]
        Configuration.set_config_model(@options)
        self.email_targets_table_set_order @options.order
        flash[:notice] = "Updated Everyone options".t 
      end
      redirect_to :action => 'index'
      return
    end    
  end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end

  class Options < HashModel
    attributes :fields => ['created', 'profile', 'source', 'lead_source', 'tag'], :order_by => 'created', :order_direction => 'DESC'

    def validate
      if self.fields
        self.errors.add(:fields, 'is invalid') if self.fields.find { |f| self.fields_options.rassoc(f).nil? }
      end

      if self.order_by
        self.errors.add(:order_by, 'is invalid') unless self.order_by_options.rassoc(self.order_by)
      end

      if self.order_direction
        self.errors.add(:order_direction, 'is invalid') unless UserSegment.order_direction_options.include?(self.order_direction)
      end
    end

    def order(opts={})
      field = self.order_by
      direction = self.order_direction
      if opts[:order]
        field, direction = opts[:order].split(' ')
      end
      direction = 'ASC' unless direction

      info = UserSegment::FieldHandler.sortable_fields(:end_user_only => true)[field.to_sym]
      return {:order => 'created_at DESC'} unless info
      field = info[:field]
      "#{field} #{direction}"
    end

    def fields_options
      UserSegment.fields_options
    end

    def order_by_options
      UserSegment.order_by_options(:end_user_only => true)
    end
  end

  def segments
    cms_page_path ['People'], 'User Lists'
    user_segments_table(false)
  end

  def create_segment
    cms_page_path ['People', 'User Lists'], 'Create a User List'

    @builder = UserSegment::OperationBuilder.new nil

    @segment = UserSegment.new :main_page => true, :segment_type => 'filtered', :order_by => 'created', :order_direction => 'DESC'

    if request.post? && params[:segment]
      return redirect_to :action => 'index' unless params[:commit]

      if @segment.update_attributes params[:segment]
        @segment.refresh
        redirect_to :action => 'segments'
      end
    end
  end

  def edit_segment
    @segment = UserSegment.find params[:path][0]

    cms_page_path ['People', 'User Lists', [@segment.name, url_for(:action => 'index', :path => @segment.id)]], 'Edit List'

    if request.post? && params[:segment]
      return redirect_to :action => 'index', :path => @segment.id unless params[:commit]

      if @segment.update_attributes params[:segment]
        self.email_targets_table_set_order @segment.order

        if @segment.should_refresh?
          @segment.refresh
          redirect_to :action => 'segments'
        else
          redirect_to :action => 'index', :path => @segment.id
        end
      end
    end
  end

  def edit_segment_filter
    @segment = UserSegment.find params[:path][0]

    if request.post? && params[:segment]
      return redirect_to :action => 'index', :path => @segment.id unless params[:commit]

      if @segment.update_attributes params[:segment]
        self.email_targets_table_set_order @segment.order

        @segment.refresh if @segment.should_refresh?
        render :partial => 'refresh_segment'
      end
    else
      render :partial => 'edit_segment_filter'
    end
  end

  def copy_segment
    segment_to_copy = UserSegment.find params[:path][0]

    cms_page_path ['People', 'User Lists', [segment_to_copy.name, url_for(:action => 'index', :path => segment_to_copy.id)]], 'Copy List'

    @segment = UserSegment.new segment_to_copy.attributes.symbolize_keys.slice(:name, :description, :fields, :main_page, :segment_options_text, :order_by, :segment_type)
    @segment.name += ' (Copy)' unless request.post?

    if request.post? && params[:segment]
      return redirect_to :action => 'index', :path => segment_to_copy.id unless params[:commit]

      if @segment.update_attributes params[:segment]
        @segment.refresh
        redirect_to :action => 'segments'
      end
    end
  end

  def refresh_segment
    @segment = UserSegment.find params[:path][0]
    @segment.refresh
    render :partial => 'refresh_segment'
  end

  def sort_segment
    @segment = UserSegment.find params[:path][0]
    @segment.resort email_targets_table_order(params)
    render :partial => 'refresh_segment'
  end

  def refresh_segment_status
    @segment = UserSegment.find params[:path][0]
  end

  def builder_help
    @handlers = UserSegment::FieldHandler.handlers
    render :action => 'builder_help', :layout => 'manage_window'
  end

  def builder
    @segment = UserSegment.find_by_id params[:path][0] if params[:path]
    @builder = @segment ? UserSegment::OperationBuilder.create_builder(@segment) : UserSegment::OperationBuilder.new(nil)
    @segment = nil if params[:copy]
    @filter = params[:filter]
    @builder.build(UserSegment::OperationBuilder.get_prebuilt_filter(@filter)) if @filter

    if request.post? && params[:builder]
      @builder.build(params[:builder])
    end

    render :action => 'builder', :layout => 'manage_window'
  end

  def update_builder
    @builder = UserSegment::OperationBuilder.new nil
    @builder.build(params[:builder])
    return render :partial => 'operation_form_operation', :locals => {:builder => @builder, :form_id => 'builder'} if params[:operation]
    return render :partial => 'operation_form_expression' if params[:expression]
    return render :nothing => true unless params[:commit]
  end

  def add_users_form
    @segment = UserSegment.find params[:segment][:id] if params[:choice] == 'existing'

    unless @segment
      @segment = UserSegment.new :main_page => true, :segment_type => 'custom'

      if request.post? && params[:segment]
        @segment.update_attributes params[:segment]
      end
    end

    @segments = UserSegment.find(:all, :conditions => {:segment_type => 'custom'}, :order => 'name')
    render :partial => 'add_users_form'
  end

  def create
    cms_page_path ['People'],'Create Contact'

    if(params[:user_options] && params[:user_options][:tag_names]) 
      @tag_names = params[:user_options].delete(:tag_names)
    end

    user_class_id = params[:user_options].delete(:user_class_id) if params[:user_options]
    @user = EndUser.new(params[:user_options])
    @user.user_class_id = user_class_id || UserClass.default_user_class_id

    if request.post? 
      if params[:commit]
	@user.errors.add(:user_clas_id) if @user.user_class.editor? && !myself.has_role?('editor_editors')

	@user.source = 'import'
	@user.admin_edit=true
	@user.valid?
	if(@user.save)
	  @user.tag_names = @tag_names if @tag_names
	  update_subscriptions(@user,params[:subscription])
	  flash[:notice] = 'Created User'.t
	  redirect_to :action => 'index'
	  return
	end
      else
	redirect_to :action => 'index'
	return
      end
    end
    
    render :action => 'edit'
  end

  def edit
    @segment = UserSegment.find_by_id(params[:path][1])  unless params[:path][1].blank?

    display_user_actions_table(false)
 
    if @segment
      cms_page_path [ 'People',
                      ["%s",url_for(:action => 'index',:path => [ @segment.id ]),@segment.name]
                    ],['Edit %s',nil,@user.name.to_s.strip.blank? ? @user.email : @user.name ] 
    else
      cms_page_path ['People'],'Edit Contact'
    end
    

    user_id = params[:path][0]
    
    @user = EndUser.find(user_id)

    
    if @user.client_user_id || (@user.user_class.editor? && !myself.has_role?('editor_editors'))
      redirect_to :action => 'index', :path => @segment ? [ @segment.id ] : nil
      return
    end

    
    if request.post?
      if params[:commit] 
        @user.user_class_id = params[:user_options].delete(:user_class_id)

        # Don't let user class be upgrade to editor if the user can edit those
        if @user.user_class.editor? && !myself.has_role?('editor_editors')
          redirect_to :action => 'index', :path => @segment ? [ @segment.id ] : nil

          return
        end

        # If it's not an editor - get rid of any editor tokens
        if  !@user.user_class.editor? 
          params[:user_options][:tokens] = AccessToken.filter_out_editor_tokens(params[:user_options][:tokens])
        end
        
        @user.attributes = params[:user_options]
        @user.admin_edit=true

        # stupid-complicated for no reason FIXME
        %w(address work_address billing_address shipping_address).each do |adr|
          address = @user.send(adr)
          if address || !params[adr].values.join("").blank?
            address ||=  @user.send("build_#{adr}")
            address.attributes = params[adr]
            instance_variable_set("@#{adr}".to_sym,address)
          end
        end
        
        if @user.save
          %w(address work_address billing_address shipping_address).each do |adr|
            adr = instance_variable_get("@#{adr}".to_sym)
            adr.update_attribute(:end_user_id, @user.id) if adr
          end
          
          @user.action('/members/edit',:admin_user_id => myself.id, :level => 0)
          update_subscriptions(@user,params[:subscription])
          flash[:notice] = 'Saved User: "%s" ' / (@user.email.blank? ? @user.name : @user.email)
          redirect_to :action =>'index', :path => @segment ? [ @segment.id ] : nil

          return
        end
      else
        redirect_to :action =>'index', :path => @segment ? [ @segment.id ] : nil

        return
      end
    end
    
    @address ||= @user.address || @user.build_address
    @work_address ||= @user.work_address || @user.build_work_address
    @billing_address ||= @user.billing_address || @user.build_billing_address
    @shipping_address ||= @user.shipping_address || @user.build_shipping_address
    
    @editing=true
    
    render :action => 'edit'
  end
  
  active_table :user_actions_table, 
              EndUserAction,
              [ "Action",
                hdr(:options,'level',:options => :level_options,:label => 'Lvl'),
                hdr(:string,'identifier'),
                hdr(:string,'renderer',:label => 'Category'),
                hdr(:string,'action',:label => 'Label'),
                hdr(:date_range,'action_at'),
                "Admin User"
              ]
  protected
  def level_options
    EndUserAction.level_select_options  
  end
  
  public
                
  def display_user_actions_table(display=true)
    @user = EndUser.find(params[:path][0]) unless @user
  
    @tbl = user_actions_table_generate params, :order => 'action_at DESC',:conditions => [ 'end_user_id=?',@user.id ],:include => [ :end_user ]
  
    render :partial => 'user_actions_table' if display
  end
  
  def view
    @user = EndUser.find(params[:path][0])

    @segment = UserSegment.find_by_id(params[:path][1])  unless params[:path][1].blank?

    display_user_actions_table(false)
 
    if @segment
      cms_page_path [ 'People',
                      ["%s",url_for(:action => 'index',:path => [ @segment.id ]),@segment.name]
                    ],['%s',nil,@user.name.to_s.strip.blank? ? @user.email : @user.name ] 
    else
      cms_page_path [ 'People'],['%s',nil,@user.name.to_s.strip.blank? ? @user.email : @user.name ] 
    end
    
    handlers = get_handler_info(:members,:view)

    tabs_to_display = Configuration.options.member_tabs
    if tabs_to_display.length > 0
      handlers = handlers.select { |hndl| tabs_to_display.include?(hndl[:identifier].to_s) }

      handlers = handlers.select do |hndl|
        hndl[:permit] ? myself.has_role?(hndl[:permit]) : true
      end

      handlers = handlers.select do |hndl|
        if hndl[:display]
          hndl[:class].send(hndl[:display],@user)
        else
          true
        end
      end
    end
    
    idx=1
    @handler_tabs = [[ "Website Visits",  jvh("MemberViewer.loadTab(1,'#{url_for :controller => '/members', :action => 'member_visits', :path => @user.id}');") ]] + 
            handlers.sort() { |hndler1,hndler2| hndler1[:name] <=> hndler2[:name] }.collect do |handler|
              idx+=1
              [ handler[:name], 
              jvh("MemberViewer.loadTab(#{idx},'#{url_for :controller => handler[:controller], :action => handler[:action], :path => @user.id}');") ]
          end
  end
  
  def login
    @user = EndUser.find_by_id(params[:path][0])
    
    if @user.client_user_id.blank? && (!@user.user_class.editor? || myself.has_role?('editor_editors'))
      process_login(@user)
      redirect_to "/"
    else
      redirect_to :action => 'view', :path => @user.id
    end
  end
  
  def member_visits
    @user = EndUser.find_by_id(params[:path][0])
    @sessions = DomainLogEntry.user_sessions @user.id
    render :partial => 'site_visits'
  end

  def member_visit_entries
    @session = DomainLogSession.find params[:path][0]
    render :partial => 'site_entries', :locals => {:entries => @session.domain_log_entries.find(:all, :order => 'occurred_at DESC')}
  end

  def add_tags_form
    render :partial => 'add_tags_form'
  end

  def quick_edit_form
    render :partial => 'quick_edit_form'
  end
  
  def remove_tags_form
    @users = EndUser.find(:all,:conditions => [ 'end_users.id IN (' + params[:user_ids].to_a.collect { |uid| DomainModel.connection.quote(uid) }.join(",") + ")" ])
  
    @existing_tags = []
    @users.each do |usr|
      @existing_tags  += usr.tags_array if usr.tags_array
    end
    @existing_tags.uniq!
    
    render :partial => 'remove_tags_form'
  end

  active_table :tags_table, TagNote,
    [hdr(:string,'tags.name',:label => 'Name'),'Count','Description' ]

  def tags
    if TagNote.count == 0
      Tag.find(:all).each do |tg|
        tg.create_tag_note unless tg.tag_note
      end
    end

    display_tags_table(false)
  end

  def tag_details
    @tag_note = TagNote.find(params[:path][0])

    if request.post? && params[:tag_note]
      if @tag_note.update_attributes( params[:tag_note])
        display_tags_table(false)
        render :update do |page|
          page << 'RedBox.close();'
          page.replace_html 'tags_table', :partial => 'tags_table'
        end
        return
      end
    end
    
    render :partial => 'tag_details'
  end

  def display_tags_table(display=true)

    cms_page_path ['People'],'Tag Details'

    @tbl = tags_table_generate params, :order =>'name',:include => :tag, :joins => :tag

    render :partial => 'tags_table' if display
  end

  def generate_vip
    @vip_number = EndUser.generate_vip
  end

  def note
    @user = EndUser.find params[:path][0]
    @note = params[:path][1] ? @user.end_user_notes.find(params[:path][1]) : @user.end_user_notes.build(:admin_user_id => myself.id)

    if request.post? && params[:note]
      if @note.update_attributes params[:note]
        @note = @user.end_user_notes.build(:admin_user_id => myself.id)
      end
    end

    @notes = @user.end_user_notes.find :all

    render :partial => 'note'
  end

  private
  
  # update users subscriptions
  def update_subscriptions(user,subscriptions)
    
    # Make sure we are updating subscriptions
    if subscriptions && subscriptions['0']
      user_subscriptions = user.user_subscription_entries.index_by(&:user_subscription_id)
      UserSubscription.find(:all).each do |sub|
        # Now create an remove subscriptions as necessary
        if subscriptions[sub.id.to_s] && !user_subscriptions[sub.id]
           sub.admin_subscribe_user(user)
        elsif !subscriptions[sub.id.to_s] && user_subscriptions[sub.id]
           user_subscriptions[sub.id].destroy
        end
      end
    end
  end
  
  
end
