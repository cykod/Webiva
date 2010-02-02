# Copyright (C) 2009 Pascal Rettig.

class MembersController < CmsController # :nodoc: all

  permit 'editor_members', :only => [ :index, :create, :edit, :view, :delete_member ]

  layout 'manage'
  
  cms_admin_paths "people",
                  "People" => { :controller => '/members' }
  
  
  # need to include 
   include ActiveTable::Controller   
   active_table :email_targets_table,
                EndUser,
                [ hdr(:icon, 'check'),
                  hdr(:static, 'edit', :width => '16'),
                  hdr(:option, 'user_level',:options => EndUser.user_level_select_options,:label => 'Lvl', :width=> 40),
                  hdr(:string, 'email'),
                  hdr(:string, 'first_name',:label => 'First'),
                  hdr(:string, 'last_name',:label => 'Last'),
                  hdr(:date_range, 'created_at',:label => 'Created'),
                  hdr(:date_range, 'registered_at',:label => 'Reg.'),
                  hdr(:option, 'user_class_id',:label=> 'Profile',:options => :get_user_classes),
                  hdr(:option, 'source',:options => EndUser.source_select_options,:label => 'Src. Type',:width=>90),
                  hdr(:string, 'lead_source',:label => 'Src.' ), 
                  'tags'
                ],
                :count_callback => 'count_end_users',
                :find_callback => 'find_end_users'
                
  
  protected 
  

  def segmentations
      @segment= session[:et]
      @segmentations = MarketSegment.find(:all,:conditions => 'segment_type = "members" AND market_campaign_id IS NULL',:order => :name).collect { |seg|
                        [ seg.name, seg.id ]
                    }

      @loaded_segment_id = session[:et_segment]
      @loaded_segment_name = session[:et_segment_name]

  end

  def count_end_users(opts)
      
      @seg = MarketSegment.new(:segment_type => 'members',:options => { :tags => @segment[:tags], :tags_select => @segment[:tags_select],
                                                                 :conditions => opts[:conditions], :order => opts[:order],
                                                                 :search => session[:active_table][:email_targets_table] })
      @seg.target_count
  end

  def find_end_users(opts)

   # (set in handle_table_actions) - if we are saving this segment, find one with the same name,
   # or create a new one
   if @save_segment
      @seg = MarketSegment.find_by_name(@save_segment,:conditions => 'segment_type="members"') || 
        MarketSegment.new(:segment_type => 'members', :name => @save_segment)
   else
     @seg = MarketSegment.new(:segment_type => 'members')
   end

   @seg.options = { :tags => @segment[:tags], :tags_select => @segment[:tags_select],
                                                                 :conditions => opts[:conditions], :order => opts[:order],
                                                                 :search => session[:active_table][:email_targets_table] }
                          
   session[:members_table_segment] = @seg.options.clone                                       
   if @save_segment
      @seg.save 
      session[:et_segment] = @seg.id
      session[:et_segment_name] = @seg.name
   end
   
   @seg.target_find(:offset => opts[:offset], :limit => opts[:limit], :order => opts[:order])
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
    elsif request.post? && params[:save_segment]
      @save_segment = params[:save_segment]
      @update_segments = true
    elsif  request.post? && params[:load_segment]
      load_segment = MarketSegment.find_by_id(params[:load_segment].to_i)

      if load_segment
        params.delete(:email_targets_table)
        session[:active_table][:email_targets_table] = load_segment.options[:search]
        session[:et] = { :tags => load_segment.options[:tags], :tags_select => load_segment.options[:tags_select] }
        session[:et_segment] = load_segment.id
        session[:et_segment_name] = load_segment.name
      else 
        session[:et_segment] = nil
        session[:et_segment_name] = nil
      end
      @update_segments = true
    elsif request.post? && params[:delete_segment]
      load_segment = MarketSegment.find_by_id(params[:delete_segment].to_i)
      load_segment.destroy
      session[:et_segment] = nil
      session[:et_segment_name] = nil
      @update_segments = true

    end
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
    
    default_options =  { :tags => [],
                         :tags_select => 'any'
                        }
  
    session[:et] ||= default_options.clone
    session[:et_segment] ||= nil

    if(params[:tag]) 
      session[:et][:tags] << params[:tag]
      session[:et][:tags].uniq!
    elsif params[:remove_tag]
      session[:et][:tags].delete(params[:remove_tag])
    elsif params[:tags_select]
      session[:et][:tags_select] = params[:tags_select]
    elsif params[:clear_tag]
      session[:et][:tags] = []
    end
    @segment= session[:et]

    @active_table_output = email_targets_table_generate params, :per_page => 25, :include => :tag_cache, :conditions => 'client_user_id IS NULL', :order => 'created_at DESC'

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
    
    #unless params[:refresh]
      #session[:et] = nil
      #session[:et_segment] = nil
    #end
    
    segmentations

    display_targets_table(false)
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
