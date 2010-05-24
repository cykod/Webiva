# Copyright (C) 2009 Pascal Rettig.

class MembersController < CmsController # :nodoc: all

  permit 'editor_members', :only => [ :index, :create, :edit, :view, :delete_member ]

  layout 'manage'
  
  cms_admin_paths "people",
                  "People" => { :controller => '/members' },
                  "User Lists" => { :action => 'segments' }
  
  
  # need to include 
  include ActiveTable::Controller   
  
  protected 

  def segmentations
    return @segmentations if @segmentations
    @segmentations = UserSegment.find(:all, :conditions => {:main_page => true, :status => 'finished'}, :order => 'name')
    @segmentations << self.segment if self.segment && ! @segmentations.find { |seg| seg.id == self.segment.id }
    @segmentations
  end

  def segment
    @segment ||= UserSegment.find_by_id params[:path][0]
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

  def find_end_users(opts)
    if self.search_results
      self.search.users
    elsif self.segment
      pages, users = self.segment.paginate self.search.page, :per_page => 25, :include => [:user_class, :domain_file]
      users
    else
      EndUser.find(:all, :conditions => 'client_user_id IS NULL', :include => [:user_class, :domain_file], :offset => opts[:offset], :limit => opts[:limit], :order => opts[:order])
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
    if request.post? && params[:table_action] && params[:user].is_a?(Hash)
      if params[:table_action] == 'delete'
        EndUser.destroy(params[:user].keys)
      else
        update_users = EndUser.find(:all,:conditions => [ 'end_users.id IN (' + params[:user].keys.collect { |uid| DomainModel.connection.quote(uid) }.join(",") + ")" ])
        
        case params[:table_action]
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
            user.tag_names = '' if user
          end
        end
      end
    end
  end
  
  def email_targets_table_generate(opts,*find_options)
    @generated_active_table_columns = [
      ActiveTable::IconHeader.new('check', :width => '16'),
      ActiveTable::StaticHeader.new('', :width => '24'),
      ActiveTable::StaticHeader.new('Profile', :width => '70'),
      ActiveTable::StaticHeader.new('Image', :width => '70'),
      ActiveTable::StaticHeader.new('Name'),
      ActiveTable::StaticHeader.new('Email')
    ]

    @fields = []
    if self.segment && self.segment.fields
      @fields = self.segment.fields
    else self.class.module_options && self.class.module_options.fields
      @fields = self.class.module_options.fields
    end

    @fields.each do |field|
      option = UserSegment.fields_options.rassoc(field)
      @generated_active_table_columns << ActiveTable::StaticHeader.new(option[1], :label => option[0]) if option
    end

    active_table_generate('end_users', EndUser, @generated_active_table_columns, {:count_callback => 'count_end_users', :find_callback => 'find_end_users'}, opts, *find_options)
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

    @active_table_output = email_targets_table_generate params, :per_page => 25, :include => :tag_cache, :conditions => 'client_user_id IS NULL', :order => self.class.module_options.order_by

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
    cms_page_path [], "People"

    return redirect_to(:action => 'segments') if self.segment && ! self.segment.ready?

    segmentations

    display_targets_table(false)
  end

   active_table :user_segments_table,
                UserSegment,
                [ hdr(:icon, 'check', :width => '16'),
                  hdr(:icon, '', :width => '32'),
                  :main_page,
                  :name,
                  :description,
                  :status,
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
    attributes :fields => [], :order_by => 'created_at DESC'

    def validate
      if self.fields
        self.errors.add(:fields, 'is invalid') if self.fields.find { |f| UserSegment.fields_options.rassoc(f).nil? }
      end

      if self.order_by
        self.errors.add(:order_by, 'is invalid') unless UserSegment.order_by_options.rassoc(self.order_by)
      end
    end
  end

  def segments
    cms_page_path ['People'], 'User Lists'
    user_segments_table(false)
  end

  def create_segment
    cms_page_path ['People', 'User Lists'], 'Create a User List'

    @builder = UserSegment::OperationBuilder.new nil

    @segment = UserSegment.new :main_page => true

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

    cms_page_path ['People', 'User Lists'], '%s User List' / @segment.name

    @builder = UserSegment::OperationBuilder.new nil

    if request.post? && params[:segment]
      return redirect_to :action => 'index', :path => @segment.id unless params[:commit]

      if @segment.update_attributes params[:segment]
        if @segment.should_refresh?
          @segment.refresh
          redirect_to :action => 'segments'
        else
          redirect_to :action => 'index', :path => @segment.id
        end
      end
    end
  end

  def copy_segment
    segment_to_copy = UserSegment.find params[:path][0]

    cms_page_path ['People', 'User Lists'], 'Copy %s User List' / segment_to_copy.name

    @builder = UserSegment::OperationBuilder.new nil

    @segment = UserSegment.new segment_to_copy.attributes.symbolize_keys.slice(:name, :description, :fields, :main_page, :segment_options_text, :order_by)
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
    redirect_to :action => 'segments'
  end

  def builder
    cms_page_path ['People'], 'Operation Builder'

    @segment = UserSegment.find_by_id params[:path][0]
    @builder = @segment ? UserSegment::OperationBuilder.create_builder(@segment) : UserSegment::OperationBuilder.new(nil)
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
    cms_page_path ['People'],'Edit Contact'
    
    user_id = params[:path][0]
    
    @user = EndUser.find(user_id)

    
    if @user.client_user_id || (@user.user_class.editor? && !myself.has_role?('editor_editors'))
      redirect_to :action => 'index'
      return
    end

    
    if request.post?
      if params[:commit] 
        @user.user_class_id = params[:user_options].delete(:user_class_id)

        # Don't let user class be upgrade to editor if the user can edit those
        if @user.user_class.editor? && !myself.has_role?('editor_editors')
          redirect_to :action => 'index'
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
          redirect_to :action =>'index'
          return
        end
      else
        redirect_to :action =>'index'
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

    display_user_actions_table(false)
  
    cms_page_path [ 'People'],['%s',nil,@user.name.to_s.strip.blank? ? @user.email : @user.name ] 
    
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
    @entry_info,@entries = DomainLogEntry.find_user_sessions(@user)
    render :partial => 'site_visits'
  end

  def add_tags_form
    @tags = EndUser.tags_count(:order => 'name')
    render :partial => 'add_tags_form'
  end
  
  def remove_tags_form
    @users = EndUser.find(:all,:conditions => [ 'end_users.id IN (' + params[:user_ids].to_a.collect { |uid| DomainModel.connection.quote(uid) }.join(",") + ")" ], :include => :tag_cache)
  
    @existing_tags = []
    @users.each do |usr|
      if !usr.tag_cache.tags.blank?
	@existing_tags  += usr.tag_cache.tags.split(",")
      end
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
