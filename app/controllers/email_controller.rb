# Copyright (C) 2009 Pascal Rettig.

class EmailController < CmsController # :nodoc: all
  layout 'manage'
  
  permit 'editor_emails'
  

 include ActiveTable::Controller   
  active_table :email_table,
                DomainEmail,
                [ ActiveTable::IconHeader.new('', :size => '12'),
                  ActiveTable::StringHeader.new('domain_emails.email', :label => 'Email'),
                  ActiveTable::OptionHeader.new('email_type',:options => DomainEmail.email_type_select_options,:label => 'Type'),
                  ActiveTable::StaticHeader.new('options',  :label => 'Options'),
                  ActiveTable::StaticHeader.new('information', :label => 'Information')
                ]
  

  def email_table_output(display=true)
  
     active_table_action('email') do |act,email_ids|
      case act
        when 'delete':
          email_ids.each do |email_id|
            email = DomainEmail.find_by_id_and_system_email(email_id,false)
            email.destroy if email
          end
        end
     end
  
     option_hash = 
        {:per_page => 25,
        :include => 'end_user'
         }

     @active_table_output = email_table_generate params, option_hash
     
     render :partial => 'email_table' if display
  end  


  def index
    cms_page_info([ ['Options', url_for(:controller => 'options') ], 'Domain Emails'],'options')
  
    email_table_output(false)
  end
  
  def new
    cms_page_info([ ['Options', url_for(:controller => 'options') ], 'Domain Emails'],'options')
  
    @email = DomainEmail.new()
    
    update
  end
  
  def edit
    cms_page_info([ ['Options', url_for(:controller => 'options') ], 'Domain Emails'],'options')
  
    @email = DomainEmail.find(params[:path][0])
    update
  end
  
  
  hide_action :update
  def update
  
    @editor_accounts = EndUser.select_options(true)
   
    new_email = !@email.id
    if request.post? && params[:email]
      @email.email = params[:email][:email] if new_email
      if(@email.update_attributes(params[:email]))
        flash[:notice] = (new_email ?  "Created Domain Email %s" : "Edited Domain Email %s" ) / ( @email.email + "@" + Configuration.domain)
        redirect_to :action => 'index'
        return
      end 
    end
  
    render :action => 'edit'
  end

end
