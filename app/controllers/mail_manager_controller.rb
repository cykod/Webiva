# Copyright (C) 2009 Pascal Rettig.

class MailManagerController < CmsController # :nodoc: all
  
  layout 'manage'
  
  permit 'editor_mailing'
  
   cms_admin_paths "mail",
                   "Mail" =>   { :action => 'index' },
                   "Mail Templates" =>  { :controller => '/mail_manager', :action => 'templates' }
                


  def index
    cms_page_path [], "Mail"

    @subpages =  [ 
      [ "Subscriptions", :editor_mailing,"mail_subscriptions.png", { :controller => '/subscription' },
          "Edit Newsletters and Mailing Lists Subscriptions" ],
      [ "Email Templates", :editor_mailing,"mail_templates.png", { :controller => '/mail_manager', :action => 'templates' },
        "Edit Mail Templates" ]
          
      ]


  end
  
  
  active_table :mail_templates_table, MailTemplate,
  [ :check,:check,:name,:subject,
    hdr(:string,'language',:label => 'Lang'),
    :created_at,:updated_at,:category
  ]


  def mail_template_options; MailTemplate.template_type_select_options; end
  
  def display_mail_templates_table(display=true)
    session['mail_templates_archived'] = @show_archived = params.has_key?(:show_archived) ? params[:show_archived] == '1' : session['mail_templates_archived']
    session['mail_templates_campaign'] = @show_campaign = params.has_key?(:show_campaign) ? params[:show_campaign] == '1' : session['mail_templates_campaign']
  
    conditions ='1'
    unless @show_archived 
      conditions += " AND mail_templates.archived = 0"
    end
    
    conditions += " AND mail_templates.template_type = '#{@show_campaign ? 'campaign' : 'site'}'"
    
    active_table_action 'mail_template' do |act,tids|
      case act
        when 'delete':  MailTemplate.delete(tids)
        when 'archive': MailTemplate.update_all('archived=1', [ 'id IN (?)',tids ])
        when 'duplicate': MailTemplate.find(tids).each { |mt| mt = mt.clone; mt.created_at = nil; mt.update_attribute(:name,mt.name + " (COPY)") }
        when 'unarchive': MailTemplate.update_all('archived=0', [ 'id IN (?)',tids ])
        when 'publish': MailTemplate.update_all('published_at=NOW()', [ 'published_at is NULL and id IN (?)',tids ])
      end
      DataCache.expire_content("Mailing")
     
    end
    
    @active_table_output = mail_templates_table_generate params, :order => 'name', :conditions => conditions
    
    render :partial => 'mail_templates_table' if display
  end
  
  
  def templates
    cms_page_path [ "Mail" ], "Mail Templates"
    
    display_mail_templates_table(false)
  end
  
  
  def add_template
    cms_page_path [ "Mail", "Mail Templates" ], 'Add Template'
    
    @mail_template = MailTemplate.new(:language => Configuration.languages[0])
    @mail_template.create_type = 'blank' unless @mail_template.create_type
    
    if request.post? && params[:mail_template]
      if @mail_template.update_attributes(params[:mail_template])
        DataCache.expire_content("Mailing")
        redirect_to :action => 'edit_template', :path => @mail_template
      end
    end
    
    
    @design_templates = [['--Select a Mail Theme--','']] + SiteTemplate.find_select_options(:all, :order => 'name',:conditions => 'template_type="mail"')
    @master_templates = [['--Select a Master Template--','']] + MailTemplate.find_select_options(:all,:order => 'name',:conditions => 'master = 1')
    
  end
  
  def generate_text_body
    render :text => MailTemplate.text_generator(params[:html])
  
  end
  
  def edit_template
    if params[:return] && params[:return_id]
      @handler_info = get_handler_info(:mail_template, :edit, params[:return])
      logger.error("mail_template edit handler #{params[:return]}(#{params[:return_id]}) not found") unless @handler_info
    end
  
    template_id = params[:path][0]
    
    @design_templates = [['--No Design Template--','']] + SiteTemplate.find_select_options(:all,:order => 'name',:conditions => 'template_type = "mail"')
    
    if @handler_info && @handler_info[:class].respond_to?(:mail_template_cms_path)
      cms_page_path *@handler_info[:class].mail_template_cms_path(self)
    else
      cms_page_path [ "Mail" ,"Mail Templates" ], "Edit Mail Template"
    end
    
    @mail_template = MailTemplate.find_by_id(template_id) || MailTemplate.new(:body_type => 'text,html', :template_type => @handler_info && @handler_info[:template_type] ? @handler_info[:template_type] : 'site')

    if request.post?
      if save_template
        DataCache.expire_content("Mailing")
        if @handler_info
          if redirect_url = @handler_info[:class].mail_template_save(@mail_template, self)
            redirect_to redirect_url
          end
        else
          if @mail_template.template_type == 'campaign'
            redirect_to :action => 'templates', :show_campaign => 1
          else
            redirect_to :action => 'templates'
          end
        end
      end
    end

    @generate_handlers = get_handler_info(:mail_manager,:generator)
  end
  
  def refresh_template
    @mail_template = MailTemplate.new(params[:mail_template])
    
    render :partial => 'edit_template_html_iframe'
  end
  
  def send_test_template
    @mail_template = MailTemplate.new(params[:mail_template])
    
    @mail_template.pre_process_file_instance_body_html
    @mail_template.replace_image_sources
    @mail_template.replace_link_hrefs
    
    
    MailTemplateMailer.deliver_to_address(params[:email],@mail_template)
  
    render :layout => false, :text =>   'Sent Email to %s' / params[:email]
  end


  def update_template
    
    template_id = params[:template_id]
    @mail_template = MailTemplate.find_by_id(template_id) || MailTemplate.new
    
    if save_template()
      @mail_templates = MailTemplate.find(:all,:order => 'name')
      @update_list = true
    end
    render :action => 'update_template'
  end
  

  def delete_template
    template_id = params[:template_id]
    
    @mail_template = MailTemplate.find(template_id)
    
    @mail_template.destroy
    
    @mail_templates = MailTemplate.find(:all,:order => 'name')
    render :partial => 'mail_templates'
  
  end
  
  private

  def save_template
    attach = params[:mail_template].delete(:attachments)
    attachments = []
    attach.split(',').each { |ath|  attachments << ath if ath && ath != '' } if attach
    params[:mail_template][:attachments] = attachments.length 
    
    if @mail_template.update_attributes(params[:mail_template])
      DataCache.expire_content("Mailing")
      @mail_template.domain_files.clear
      if attachments.is_a?(Array)
        attachments.each do |atch| 
          dmn_file = DomainFile.find_by_id(atch)
          @mail_template.domain_files << dmn_file if dmn_file
        end
      end
      
      return true
    end
    return false
  end
  
end
