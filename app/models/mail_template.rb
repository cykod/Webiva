# Copyright (C) 2009 Pascal Rettig.

require 'hpricot'

=begin rdoc
MailTemplate's are used to store custom admin-defined messages that
can be sent by the system. Paragraphs options and triggered actions can store
the id of a MailTemplate template to use, alternatively custom modules
can use MailTemplate#fetch to fetch templates by name so that templates id
don't need to be configured.

=== Variable substituion
MailTemplate's support variable substitution using the standard %%var_name%% variables.
Which variables are used are custom by actual usage and should be described in the location
where the email template can be selected (TODO: Add in registration for mail handler types 
with lists of variables used) 


=== Using Mail Templates
MailTemplates are generally created in e-marketing => Email Templates, but to
use one you can use MailTemplate#deliver_to_address  or MailTemplate#deliver_to_user 
for example:

     @mail_template = MailTemplate.find_by_id(@options.mail_template_id)
     @replacement_variables = { :url => url,
                               :link => "<a href='#{url}'>#{url}</a>" }

     @mail_template.deliver_to_email('test@domain.com',@replacement_variables)
                             OR
     @mail_template.deliver_to_user(myself,@replacement_variables)

=== Template Types
There are two types of templates - site and campaign - the former are for usage in the site,
the later are for usage in the mailing module to send email campaigns. In general if you are
asking a user to select a template you used use MailTemplate#self.site_template_options to 
have them pick a template.


=end
class MailTemplate < DomainModel
 validates_presence_of :subject,  :on => :update
 validates_presence_of :name
 validates_presence_of :language,  :on => :create

 has_and_belongs_to_many :domain_files, :join_table => 'domain_files_mail_templates'
  
 belongs_to :site_template
 
 has_options :template_type, [['Site Template','site'],['Campaign Template','campaign']]

 process_file_instance :body_html, :body_html_display

 
 
 attr_reader :prepared_body
 
 attr_accessor :generate_text_body
 
 attr_accessor :attachment_list
 attr_accessor :create_type
 attr_accessor :master_template_id
 attr_accessor :mailing_handler
 attr_accessor :webiva_message_id

 @@text_regexp = /\%\%(\w+)\%\%/
 @@html_regexp = /\<span\s+(class=\"mceNonEditable\"\s*|alt=\"cmsField\"\s*){2}\>\<span.*?alt=\"([^\"]+)\".*?\<\/span\>\<\/span\>/
 @@href_regexp = /\<a([^\>]+?)href\=(\'|\")([^\'\"]+)(\'|\")([^\>]*?)\>/mi
 @@src_href = /\<img([^\>]+?)src\=(\'|\")([^\'\"]+)(\'|\")([^\>]*?)\>/mi
 
 private
 
 def invalid_variable(var) #:nodoc:
  '' #var 
  
  #@invalid_variable || 'Invalid Variable'.t
 end
 
 
 
 public
 
 # Returns a select-friendly list of site templates
 def self.site_template_options; self.find_select_options(:all,:conditions => 'template_type = "site" AND archived=0');  end

 # Returns a select-friendly list of campaign templates
 def self.campaign_template_options; self.find_select_options(:all,:conditions => 'template_type = "campaign" AND archived=0');  end
 
 # Generate text from HTML - moved to util
 def self.text_generator(html) #:nodoc:
    Util::TextFormatter.text_formatted_generator(html)
 end
 
 def before_validation #:nodoc:
   self.body_html.gsub!('/website/mail_manager/edit_template/','') unless self.body_html.blank?
   self.body_text.gsub!('/website/mail_manager/edit_template/','') unless self.body_text.blank?
   if(self.body_text.blank? && self.generate_text_body && self.generate_text_body.to_s != "0")
     self.body_text = self.class.text_generator(self.body_html)
   end
   self.language ||= Configuration.languages[0]
 end

 def validate_on_create #:nodoc:
  if self.create_type
    case create_type
    when 'master':
      errors.add(:master_template_id,'is missing') if master_template_id.blank?
    when 'design':
      errors.add(:site_template_id,'is missing') if site_template_id.blank?
    end
  end
 end  

 def validate
   if self.template_type == 'campaign' && self.id
     if self.body_format == 'html'
       errors.add(:body_type, 'is invalid. (Campaign template types can be text or both.)')
     else
       errors.add(:body_text, 'is missing. (Campaign template types require a text version.)') if self.body_text.blank? || self.body_text.strip.blank?
     end
   end
 end

 def render_subject(vars) #:nodoc:
  subject.gsub(@@text_regexp) do |mtch|
        vars[$1]  || invalid_variable($1)
  end
 
 end
 
 # Create and save a deep clone of this template - with a modified title
 def duplicate
  new_tpl = self.clone
  new_tpl.name += ' (Copy)'.t
  new_tpl.save
  
  self.domain_files.each do |df| 
    new_tpl.domain_files << df
  end
  
  new_tpl
  
 end
 
 # Find a template by name (optionally by language)
 def self.fetch(name,options={})
  order = options[:language] ? 'language=' + self.connection.quote(options[:language].downcase) + ' DESC, language="en" DESC' : nil
  self.find(:first,:conditions => ['name = ?',name.to_s],:order => order)
 end
 
 # Deliver this template to an email address
 def deliver_to_address(email,variables={})
  MailTemplateMailer.deliver_to_address(email,self,variables)
 end
 
 # Deliver this template to a EndUser (first_name,last_name,etc will be available as variables)
 def deliver_to_user(usr,variables={})
  MailTemplateMailer.deliver_to_user(usr,self,variables)
 end
 
 # Return a list of attachments
 def attachments 
  if @attachment_list.is_a?(Array)
    @attachment_list.length > 0 ?  DomainFile.find(:all,:conditions => "id IN (#{@attachment_list.collect { |df| connection.quote(df) }.join(",")})") : []
  else
    self.domain_files
  end
 end
 
 # Return the body format string - text, html, both or none
 def body_format
  if is_html && is_text
      'both'
    elsif is_html
      'html'
    elsif is_text 
      'text'
    else
      'none'
  end
 end
 
 # Is this an html email ?
 def is_html
  self.body_type.include?('html')
 end
 
 # is this a text email
 def is_text
  self.body_type.include?('text')
 end
 
 def render_text(vars) #:nodoc:
  prepare_template
  
  @prepared_body[:text_sections].inject('') do |output,item|
    if item.is_a?(String)
      output + item
    else
      output + (vars[item[:var]] || invalid_variable(item[:var])).to_s
    end
  end
 end
 
 # HTML allows both types of variables
 def render_html(vars) #:nodoc:
  vars ||= {}
  prepare_template
  
  @prepared_body[:html_sections].inject('') do |output,item|
    if item.is_a?(String)
      output + item
    else
      output + (vars[item[:var]] || invalid_variable(item[:var])).to_s.gsub("\n","\n<br/>")
    end
  end

 end

 
 def get_variables #:nodoc:
  vars = []
  subject.to_s.scan(@@text_regexp) do |mtch|
    vars << $1
  end
  body_text.to_s.scan(@@text_regexp) do |mtch|
    vars << $1
  end
  body_html.to_s.scan(@@html_regexp) do |mtch|
    vars << $2
  end
  body_html.to_s.scan(@@text_regexp) do |mtch|
    vars << $1
  end
  
  vars.uniq.sort
 end
 
 def get_links #:nodoc:
    links = []
    (body_html_display || body_html).scan(@@href_regexp) do |mtch|
      href = $3
      if !(href =~ /^[a-zA-Z0-9]+\:.*$/)
        links << href
      end
    end
    
    links.uniq
 end
 
 
 def prepare_to_send #:nodoc:
  if !@prepared_body
    @prepared_body = {}
    @prepared_body[:html] ||= body_html_display || body_html if is_html
    @prepared_body[:text] ||= body_text if is_text
    
    # Replace any of the HTML type variables
    # With other type variables
    if is_html
      @prepared_body[:html].gsub!(@@html_regexp) do |mtch|
	      "%%#{$2}%%"
      end
	
      if self.site_template
        pre_output = ''
        post_output = ''
        pre = true
        self.site_template.render_html((Locale.language_code||'en').downcase) do |part|
          if pre
            pre_output += part.body
          else
            post_output += part.body
          end
          if part.zone_position == 1
            pre = false
          elsif !part.variable.blank? 
            if pre
              pre_output += site_template.render_variable(part.variable,nil,Locale.language_code.downcase)
            else
              post_output += site_template.render_variable(part.variable,nil,Locale.language_code.downcase)
            end
          end
        end
        @prepared_body[:html] = pre_output + @prepared_body[:html] + post_output
        @prepared_body[:html] = transform_html(@prepared_body[:html])
      else
        @prepared_body[:html] = @prepared_body[:html]
      end        
      
     end
   end
   
 end
 
 
 @@src_href = /\<img([^\>]+?)src\=(\'|\")([^\'\"]+)(\'|\")([^\>]*?)\>/mi 
 def replace_image_sources #:nodoc:
  prepare_to_send
  if is_html
    @prepared_body[:html].to_s.gsub!(@@src_href) do |mtch|
      src=$3
      # Only replace absolute urls
      if src[0..0] == '/'
        src = "http://" + Configuration.full_domain + src
      end
     "<img#{$1}src='#{src}'#{$5}>"
    end
  end
 end
 
 # Add in a variable for a tracking image
 # add in a spacer if necessary
 def replace_tracking_image #:nodoc:
  prepare_to_send
  if is_html
    replaced_variable = false
    #@prepared_body[:html].sub!(@@src_href) do |mtch|
    #  replaced_variable = "track_image:#{$3}"
    #  src = "%%#{replaced_variable}%%"
    # "<img#{$1} src='#{src}'#{$5}>"
    #end
    
    # add in a spacer image if no other image available
    if !replaced_variable
      replaced_filename = "#{RAILS_ROOT}/public/images/spacer.gif"
      replaced_variable = "track_image:http://#{Configuration.full_domain}/images/spacer.gif"
      @prepared_body[:html] = @prepared_body[:html].to_s + "<img src='%%#{replaced_variable}%%' width='1' height='1' />"
    end
    
    return replaced_filename ,replaced_variable
  end
  return nil
 end
 
 def view_online_href #:nodoc:
  prepare_to_send
  # View online only makes sense for HTML email
  if is_html
    view_online_var = "track_view_online:link"
    view_online_html = "<font face='arial,sans-serif' size='1'><div align='center' class='view_online_link'>#{'Trouble viewing this email? You can'.t} <a target='_blank' href='%%#{view_online_var}%%'>#{'View this Message Online'.t}</a></div></font><br/>"
    @prepared_body[:html] =  view_online_html + @prepared_body[:html]
    view_online_var
  end
 
 end
 
 def unsubscribe_text #:nodoc:
    "Remove your name from any future %s mailing: " / Configuration.domain
 end
 
 def add_unsubscribe_links #:nodoc:
  prepare_to_send
  unsubscribe_var ="track_unsubscribe:link"
  if is_html
    unsubscribe_html =  "<br/><br/><font face='arial,sans-serif' size='1'><div align='center' class='unsubscribe_link'><a target='_blank' href='%%#{unsubscribe_var}%%'>#{'Unsubscribe your email'.t}</a>  #{'from any future %s mailings.' / Configuration.domain}"
    unsubscribe_html << "<br/>" + Configuration.options.one_line_address + "</div></font>"
    @prepared_body[:html] += unsubscribe_html
  end
  if is_text
    unsubscribe_text = "\n\n#{'To unsubscribe from any future %s mailings, goto:' / Configuration.domain }%%#{unsubscribe_var}%%"
    unsubscribe_text << "\n" + Configuration.options.one_line_address
    @prepared_body[:text] ||= ''
    @prepared_body[:text] += unsubscribe_text
  end
  
  unsubscribe_var
 end
 
 def track_link_hrefs #:nodoc:
  prepare_to_send
  if is_html
    links = []
    @prepared_body[:html] ||= body_html_display || body_html
    @prepared_body[:html].gsub!(@@href_regexp) do |mtch|
      whole_match = $&
      href=$3
      pre=$1
      post=$5
      # Ignore non-standard links
      # e.g. mailto, javacript, skype, etc
      if (href =~ /^http(s){0,1}\:\/\//) || !(href =~ /^[a-zA-Z0-9]+\:{1}.*$/)
	links << href
	href = "%%track:" + href + "%%"
        "<a#{pre}href='#{href}'#{post} target='_blank'>"
      else
        whole_match
      end
    end
    return links.uniq
  else
    return []
  end
 end
 
 # Replace all site links with full http:// links
 # Only necessary if not tracking links
 def replace_link_hrefs #:nodoc:
  prepare_to_send
  if is_html
    @prepared_body[:html].gsub!(@@href_regexp) do |mtch|
      href=$3
      # Only replace absolute urls
      if href[0..0] == '/'
	href = "http://" + Configuration.full_domain + href
      end
    "<a#{$1}href='#{href}'#{$5} target='_blank'>"
    end
  end
 end
 
 def prepare_template #:nodoc:
   return if @prepared_body && (@prepared_body[:html_sections] || @prepared_body[:text_sections])
   prepare_to_send
   replace_link_hrefs
   replace_image_sources
   
    
   if is_html && !@prepared_body[:html_sections]
    html_sections = []
        
    remaining_html = parseValues(@prepared_body[:html],'\%\%') do |text_before_var,var|
        html_sections  << text_before_var
        html_sections  << { :var => var }
    end
     
    html_sections  << remaining_html
    
    @prepared_body[:html_sections] = html_sections
    @prepared_body[:html] = nil
  end
  
  if is_text && !@prepared_body[:text_sections]
    text_sections = []
      
    remaining_text = parseValues(@prepared_body[:text],'\%\%') do |text_before_var,var|
      text_sections  << text_before_var
      text_sections  << { :var => var }
    end
    
    text_sections  << remaining_text 
    
    @prepared_body[:text_sections] = text_sections
    @prepared_body[:text] = nil
  end
  
 end
 
 def transform_html(html) #:nodoc:
   return html if !self.site_template
    
   styles = self.site_template.full_styles_hash((Locale.language_code||'en').downcase)  
    # Get all the styles together
   doc = Hpricot(html)
    
   doc.each_child do |elm|
    if !elm.text?
      transform_tag(elm,styles)
    end
   end 
   
   return doc.to_html
 end
 
 def additional_headers(variables={})
   headers = {'X-Webiva-Domain' => DomainModel.active_domain_name}
   headers['X-Webiva-Handler'] = self.mailing_handler if self.mailing_handler
   headers['X-Webiva-Message-Id'] = self.webiva_message_id if self.webiva_message_id
   headers['Reply-to'] = variables['system:reply_to'] if variables['system:reply_to']
   headers
 end

 private

 def transform_tag(tag,styles) #:nodoc:
   begin
      if !tag.bogusetag? && !tag.comment?
        styles_txt = ''
        
        styles_txt += styles[tag.name] if styles[tag.name]
        if tag.attributes['class']
          styles_txt += styles['.' + tag.attributes['class']] if styles['.' + tag.attributes['class']]
          styles_txt += styles[tag.name + '.' + tag.attributes['class']] if styles[tag.name + '.' + tag.attributes['class']]
        end
        
        if tag.attributes['id']
          styles_txt += styles['#' + tag.attributes['id']] if styles['#' + tag.attributes['id']]
        end
        
        
        unless styles_txt.blank?
          tag['style'] = tag['style'].to_s + ' ' + styles_txt
        end
      end
    rescue Exception => e
      #
    end
    
    if tag.respond_to?('each_child')
      tag.each_child do |elm|
        if !elm.text?
          transform_tag(elm,styles)
        end
      end 
    end
  end
 
 def parseValues(body,regexp_delim) #:nodoc:
    re = Regexp.new("#{regexp_delim}([^#{regexp_delim}]+?)#{regexp_delim}",Regexp::IGNORECASE | Regexp::MULTILINE)
    
    while(mtch = re.match(body) )
      yield mtch.pre_match,mtch[1]
      body = mtch.post_match
    end
    
    return body
  end
    
end
