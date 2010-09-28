# Copyright (C) 2009 Pascal Rettig.

class TriggeredActionController < WizardController  # :nodoc: all
  
  permit ['editor_content','editor_mailing']
  
  wizard_steps [ [ 'index', 'Trigger &amp; Action' ],
                 [ 'options', 'Options' ],
                 [ 'confirm', 'Confirm' ] ]
  layout 'manage_window'
  

  private
  
  def get_available_trigger(trigger_type,trigger_id)
    case trigger_type
    when 'publication':
      publication = ContentPublication.find(trigger_id)
      publication.triggered_actions.build
    when 'page_paragraph':
      paragraph = PageParagraph.find(trigger_id)
      paragraph.triggered_actions.build
    else
      raise 'Invalid Trigger'
    end
  end
  
  public
  
  def index
    TriggeredAction.delete_all(['comitted = 0  AND created_at < ?',1.days.ago]) 
    
    @action_id = params[:action_id]
    if params[:previous]
      @action_id = session[:triggered_action_wizard][:triggered_action_id]
    else 
      session[:triggered_action_wizard] ||= {}
      session[:triggered_action_wizard][:callback] = params[:callback] if params[:callback]
    end 
    
    
    if params[:trigger] && params[:trigger_id]
      @trigger_type = params[:trigger]
      @trigger_id = params[:trigger_id]
      @triggered_action = get_available_trigger(@trigger_type,@trigger_id)
      
      
    elsif @action_id
      @triggered_action = TriggeredAction.find(@action_id)
      @enable_next = true
    else
      raise 'Invalid Triggered Action'
    end
  
    if request.post? 
      if @triggered_action.update_attributes(params[:triggered_action])
        session[:triggered_action_wizard][:triggered_action_id]  = @triggered_action.id
        redirect_to :action => 'options'
        return
      end
      @enable_next = false
    end 
    @triggers = @triggered_action.triggers
    @actions = TriggeredAction.available_actions_options

    render :action => 'index', :layout =>  'manage_window'
  end
  


  def options
  
    @enable_next = true
    
    @action_id = session[:triggered_action_wizard][:triggered_action_id]
    @triggered_action = TriggeredAction.find(@action_id)
    
    @action_options = @triggered_action.action_options(params[:options])
    
    
    if request.post? 
      if @action_options.valid?
        @action_options.option_to_i(:user_class)
        @action_options.option_to_i(:publication_id)
        @action_options.option_to_i(:detail_page)
        @triggered_action.data = @action_options.to_h
        @triggered_action.save
        redirect_to :action => 'confirm'
        return
      end
    end
  end
  
  
  def confirm
    @action_id = session[:triggered_action_wizard][:triggered_action_id]
    @triggered_action = TriggeredAction.find(@action_id)
  
    @next_button = 'Submit'
    @finished_onclick = "window.opener.#{session[:triggered_action_wizard][:callback]}(#{@triggered_action.id}); setTimeout(function() { window.close(); },10);"
  end
  
  helper_method :available_user_classes
  def available_user_classes  
    [ ['--Select User Class--', nil ] ] + UserClass.find(:all).collect { |itm| [itm.name,itm.id ] }
  end
  
  helper_method :available_display_publication
  def available_display_publication
    if @triggered_action.trigger_type == 'ContentPublication'  
      [ ['--No Publication--', nil ] ] + ContentPublication.find(:all,:conditions => ['publication_type="view" AND content_model_id=?', @triggered_action.trigger.content_model_id]).collect { |itm| [itm.name,itm.id] }
    else
      []
    end
  end
  
  helper_method :available_detail_page
  def available_detail_page
    [['--No Detail Page--', nil ]] + SiteNode.page_options
  end
  
end
