# Copyright (C) 2009 Pascal Rettig.

class Editor::AuthFeature < ParagraphFeature


  


  feature :login, :default_data => { },
  :default_feature => <<-FEATURE
  <div>
    <cms:logged_in>
      <cms:trans>Welcome Back</cms:trans> <cms:name/>
      <br/>
      <a <cms:logout_href/>><cms:trans>Logout</cms:trans></a>
    </cms:logged_in>
    <cms:login_form>
      <table>
      <cms:error>
      <tr>
      <td colspan="2"><cms:trans>Invalid Login</cms:trans></td>
      </tr>
      </cms:error>
      
      <cms:use_email>
      <tr>
      <td><cms:trans>Email</cms:trans>:</td>
      <td><input type='text' <cms:email/> size='20'/></td>
      </tr>
      </cms:use_email>
      
      <cms:use_username>
      <tr>
      <td><cms:trans>Username</cms:trans>:</td>
      <td><input type='text' <cms:username/> size='20'/></td>
      </tr>
      </cms:use_username>
      
      
      
      <tr>
      <td><cms:trans>Password</cms:trans>:</td>
      <td><input type='password' <cms:password/> size='20' /></td>
      </tr>
      <tr>
      <td colspan='2' align='right'/>
      <input type='submit' value='<cms:trans>Login</cms:trans>'/>
      </td>
      </tr>
      </table>
    </cms:login_form>
  </div>
  
  FEATURE
  
  
  def login_feature(data)
    webiva_feature(:login) do |c|
      c.define_tag 'logged_in' do |tag|
        if data[:user]
          tag.expand
        else
          ''
        end
      end
      c.define_tag 'login_form' do |tag|
        # Go through each section
        # Set the local to this
        if data[:user]
          ''
        else
          form_tag('')  + tag.expand + "</form>"
        end
      end
      c.define_tag('email') { |tag| "name='cms_login[login]' id='cms_login_login'" }
      c.define_tag('username') { |tag| "name='cms_login[username]' id='cms_login_username'" }
      c.define_tag('password') { |tag|  "name='cms_login[password]' id='cms_login_password'" }
      
      c.define_tag('remember') { |tag| "type='checkbox' name='cms_login[remember]' value='1' id='cms_login_remember'" }
      
      c.define_tag 'error' do |tag|
        if data[:error]
          tag.expand
        else
          ''
        end
      end
      

      
      c.define_tag 'logged_in:name' do |tag|
        data[:user].first_name.blank? && data[:user].last_name.blank? ? '' : data[:user].name 
      end
      c.define_value_tag('logged_in:first_name'){ |tag| data[:user].first_name }
      c.define_value_tag('logged_in:last_name'){ |tag| data[:user].last_name }
      
      c.define_tag 'logged_in:logout_href' do |tag|
        if editor?
          "href='javascript:void(0);'"
        else
          "href='#{page_path}?cms_logout=1'"
        end
      end
      
      c.define_expansion_tag('use_username') { |tag| data[:type] =='username' }
      c.define_expansion_tag('use_email') { |tag| data[:type] =='email' }
    end
  end

  
 feature :missing_password, :default_feature => <<-FEATURE_DEFAULTS
    <cms:missing_password>
      <cms:invalid_verification>
      <p><b>The verfication code you entered is invalid or has already been used</b></p>
      </cms:invalid_verification>

      <p>Please enter the email account you registered with. If that email is in the system, you will be sent a link that will allow you to access your account and reset your password</p>
      Email: <cms:email/><cms:submit>Send Email</cms:submit>
    </cms:missing_password>
    <cms:template_sent>
      <p>If the email you entered was a valid email registered with this system you will receive an email containing a link that will allow you 1-time access to your account</p>
    </cms:template_sent>
    
    FEATURE_DEFAULTS
  
  
  def missing_password_feature(data)
    webiva_feature(:missing_password,data) do |c|
      c.define_tag 'missing_password' do |tag|
        if data[:state] == 'missing_password'
          form_tag('') +  tag.expand + "</form>"
        else
          nil
        end
      end
      
      c.define_tag 'invalid_verification' do |tag|
        data[:invalid] ? tag.expand : nil
      end
      
      c.define_tag 'missing_password:email' do |tag|
        "<input type='text' name='missing_password[email]' value=''/>"
      end
      
      c.define_tag 'missing_password:submit' do |tag|
        "<input type='submit' value='#{vh tag.expand}' />"
      end
      
      c.define_tag 'template_sent' do |tag|
        data[:state] == 'template_sent' ? tag.expand : nil
      end
      
   end
  end

  

  feature :enter_vip, :default_feature => <<-FEATURE
    <cms:unregistered>
      <cms:failure><cms:trans>Invalid VIP #</cms:trans><br/></cms:failure>
      <cms:registered><cms:trans>VIP # Already Used</cms:trans><br/></cms:registered>
      VIP # <cms:input size='10'/><input type='submit' value='<cms:trans>Enter</cms:trans>'/>
    </cms:unregistered>
  FEATURE
    
  
 def enter_vip_feature(data)
   webiva_feature(:enter_vip,data) do |c|
     c.form_for_tag('unregistered','vip') { |t| !data[:registered] ? HashObject.new : nil }
     c.expansion_tag('registered')  { |t|  data[:registered] }
     c.expansion_tag('failure') { |t| data[:failure] }
     c.define_tag('unregistered:input') do |tag|
        size = tag.attr['size'] ? tag.attr['size'].to_i : 10
        "<input type='text' name='vip[number]' id='vip_number' size='#{size}' />"
      end
   end
  end

 feature :email_list, :default_feature => <<-FEATURE
  <div>
    <cms:submitted>
      <cms:trans>Your email has been submitted to our list</cms:trans>
    </cms:submitted>
    <cms:form>
    <cms:errors>
    <div class='error'>
        <cms:value/>
    </div>
    </cms:errors>
    <table>
    <tr>
      <td class='label'>Email:*</td>
      <td class='data'><cms:email/></td>
    </tr>
    <tr>
      <td class='label'>Zip:</td>
      <td class='data'><cms:zip/></td>
    </tr>
    <tr>
      <td>
      <cms:button>Signup</cms:button>
      </td>
    </tr>
    </table>
    </cms:form>
  </div>
  
  FEATURE

  
  
  def email_list_feature(data)
    webiva_feature(:email_list,data) do |c|
      c.form_for_tag('form','email_list_signup') { !data[:submitted] ? data[:email_list] : nil }
      
      c.define_form_error_tag('form:errors')
      
      c.define_form_field_tag('form:email')
      c.define_form_field_tag('form:zip')
      c.define_form_field_tag('form:first_name')
      c.define_form_field_tag('form:last_name')
      
      c.define_button_tag('form:button')
      
      c.expansion_tag('submitted') { |t| data[:submitted] }
    end
  end
  


end
