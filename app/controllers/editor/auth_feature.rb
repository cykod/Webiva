# Copyright (C) 2009 Pascal Rettig.

class Editor::AuthFeature < ParagraphFeature #:nodoc:all


  feature :user_register, :default_feature => <<-FEATURE
<cms:registered>
You are already registered
</cms:registered>
<cms:register> 
 <ol class='webiva_form register_form'>
  <cms:errors><li class='errors'><cms:value/></li></cms:errors>
  <!-- enter form elements directly -->
  
  <li><cms:email_label/><cms:email/></li>

  <cms:any_field except='email'>
     <li><cms:label/><cms:control/></li>
  </cms:any_field>
  <!-- optional fields except='field1' or fields="field1,field2" options work too -->


 <cms:publication>
 <cms:field><cms:item/></cms:field>
 </cms:publication>

  <li class='captcha'><cms:captcha/></li>
  <li class='button'><cms:submit/></li>
  </ol>
</cms:register>


FEATURE
  
  def user_register_feature(data)
    webiva_custom_feature(:user_register,data) do |c|
      c.expansion_tag('registered') { |t| data[:registered] }
      c.form_for_tag('register',:user) { |t| data[:usr] ? data[:usr] : nil }

      c.form_error_tag('register:errors') { |t| [ data[:usr], data[:address], data[:business], data[:model] ]}

      data[:options].all_field_list.each do |fld|
        c.field_tag("register:#{fld[0]}",{ :control => fld[1][1]}.merge(fld[1][3]||{}))
      end

      ['any_field','required_field','optional_field'].each do |fields|
        user_fields_helper('register',c,fields,data,(data[:options].always_required_fields + data[:options].required_fields))
      end

      c.fields_for_tag('register:address',:address) { |t| data[:address] ? data[:address] : nil }
      user_fields_helper('register:address',c,'address_field',data,data[:options].address_required_fields)

       data[:options].address_field_list.each do |fld|
        c.field_tag("register:address:#{fld[0]}",{ :control => fld[1][1]}.merge(fld[1][3]||{}))
      end

      c.fields_for_tag('register:business',:business) { |t| data[:business] ? data[:business] : nil }
      user_fields_helper('register:business',c,'business_address_field',data,data[:options].work_address_required_fields)
      
      data[:options].business_address_field_list.each do |fld|
        c.field_tag("register:business:#{fld[0]}",{ :control => fld[1][1]}.merge(fld[1][3]||{}))
      end

      if data[:options].publication
        c.fields_for_tag('register:publication',:model,:local => 'pub') { |t|  data[:model] }
        c.publication_field_tags("register:publication",data[:options].publication, :local => 'pub')
      else
        c.expansion_tag('register:publication') { |t| nil }
      end
      c.captcha_tag('register:captcha') { |t| data[:captcha]}

      c.button_tag('register:submit')

      data[:options].register_features.each do |feature|
        feature.feature_instance.feature_tags(c,data[:feature])
      end
    end
  end


  feature :user_edit_account, :default_feature => <<-FEATURE
<cms:edit>
  <cms:reset_password>Reset your password.</cms:reset_password>
  <cms:updated>Account Updated.</cms:updated>

 <ol class='webiva_form edit_account_form'>
 <!-- enter form elements directly -->
  <cms:errors><li class='errors'><cms:value/></li></cms:errors>

  <li><cms:email_label/><cms:email/></li>

  <cms:any_field except='email'>
     <li><cms:label/><cms:control/></li>
  </cms:any_field>
  <!-- optional fields except='field1' or fields="field1,field2" options work too -->


 <cms:publication>
 <cms:field><cms:item/></cms:field>
 </cms:publication>

 <li class='button'><cms:submit/></li>
  </ol>
</cms:edit>


FEATURE
  
  def user_edit_account_feature(data)
    webiva_custom_feature(:user_edit_account,data) do |c|
      c.form_for_tag('edit',:user,:html => { :enctype => 'multipart/form-data' }) { |t| data[:usr] ? data[:usr] : nil }
      c.form_error_tag('edit:errors') { |t| [ data[:usr], data[:address], data[:business], data[:model] ]}

      c.expansion_tag('edit:updated') { |t| data[:updated] }
      c.expansion_tag('edit:reset_password') { |t| data[:reset_password] }

      data[:options].all_field_list.each do |fld|
        c.field_tag("edit:#{fld[0]}",{ :control => fld[1][1]}.merge(fld[1][3]||{}))
      end

      ['any_field','required_field','optional_field'].each do |fields|
        user_fields_helper('edit',c,fields,data,data[:options].required_fields)
      end

      c.fields_for_tag('edit:address',:address) { |t| data[:address] ? data[:address] : nil }
      user_fields_helper('edit:address',c,'address_field',data,data[:options].address_required_fields)

       data[:options].address_field_list.each do |fld|
        c.field_tag("edit:address:#{fld[0]}",{ :control => fld[1][1]}.merge(fld[1][3]||{}))
      end

      c.fields_for_tag('edit:business',:business) { |t| data[:business] ? data[:business] : nil }
      user_fields_helper('edit:business',c,'business_address_field',data,data[:options].work_address_required_fields)
      
      data[:options].business_address_field_list.each do |fld|
        c.field_tag("edit:business:#{fld[0]}",{ :control => fld[1][1]}.merge(fld[1][3]||{}))
      end

      if data[:options].publication
        c.fields_for_tag('edit:publication',:model) { |t|  data[:model] }
        c.publication_field_tags("edit:publication",data[:options].publication)
      else
        c.expansion_tag('edit:publication') { |t| nil }
      end
      
      c.button_tag('edit:submit')

      data[:options].user_edit_features.each do |feature|
        feature.feature_instance.feature_tags(c,data[:feature])
      end

    end
  end



  def user_fields_helper(prefix,c,fields_name,data,required_fields=[])
    c.loop_tag("#{prefix}:#{fields_name}") do |t|
      fields = data[:options].send("#{fields_name}_list") || []
      if t.attr['except']
        except_fields = t.attr['except'].split(",").map { |elm| elm.blank? ? nil : elm.strip }.compact
        fields = fields.select { |elm| !except_fields.include?(elm[0].to_s) }
      end
      if t.attr['fields']
        only_fields = t.attr['fields'].split(",").map { |elm| elm.blank? ? nil : elm.strip }.compact
        fields = fields.select { |elm| only_fields.include?(elm[0].to_s) }
      end
      fields
    end
    c.value_tag("#{prefix}:#{fields_name}:label") do |t|
      fld =  t.locals.send(fields_name)
      frm =  t.locals.form
      req = required_fields.include? fld[0].to_s
      content_tag("label",
                  t.locals.send(fields_name)[1][0] + (req ? "<em>*</em>" : ""),
                 :for => "#{frm.object_name}_#{fld[1[2]]}")
    end
    c.value_tag("#{prefix}:#{fields_name}:control") do |t|
      frm = t.locals.form
      c.form_field_tag_helper(t,frm,t.locals.send(fields_name)[1][1],t.locals.send(fields_name)[1][2],t.locals.send(fields_name)[1][3]||{})
    end
    c.value_tag("#{prefix}:#{fields_name}:error") do |t|
      c.form_field_error_tag_helper(t,t.locals.form, t.locals.send(fields_name)[0].to_s)
    end
    c.expansion_tag("#{prefix}:#{fields_name}:required") do |t|
      required_fields.include? t.locals.send(fields_name)[0].to_s
    end
  end


  feature :user_activation, :default_feature => <<-FEATURE
<cms:activation>
<cms:acceptance_error>You must accept the terms and conditions to continue</cms:acceptance_error>
I agree to the terms and conditions of this site <br/><br/>

<cms:check/>
 <cms:submit/>

</cms:activation>
<cms:activated>
Your account has been activated. 
</cms:activated>
<cms:already_activated>Your account has already been activated</cms:already_activated>
<cms:invalid_link>
 The link you used is not valid. Please contact us to request a new activation link.
</cms:invalid_link>

FEATURE

  def user_activation_feature(data)
    webiva_feature(:user_activation) do |c|
      c.form_for_tag('activation',:activate) do  |t| 
        if  data[:activation_object]
        {  :object => data[:activation_object],
           :code => tag('input',:type => 'hidden',:name => 'activate[code]', :value => data[:activation_object].code )
        }
        else
          nil
        end

      end
       c.expansion_tag('activation:acceptance_error') {  |t| data[:acceptance_error]}
       c.field_tag('activation:check',:field => 'accept',:control => 'check_boxes',:single => true) do  |t| 
        [ [ t.attr['label'] || 'I accept the terms and conditions', true ]] 

       end
       c.button_tag('activation:submit',:value => 'Submit')
      c.expansion_tag('activated') {  |t| data[:status] == 'activated' }
      c.expansion_tag('already_activated') {  |t| data[:status] == 'already_activated' }
      c.expansion_tag('invalid_link') {  |t| data[:status] == 'invalid' }
      
     
    end
  end

  
  feature :login, :default_data => { },
  :default_feature => <<-FEATURE
  <div>
    <cms:logged_in>
      <cms:trans>Welcome Back</cms:trans> <cms:name/>
      <br/>
      <cms:logout_link>Logout</cms:logout_link>
    </cms:logged_in>
    <cms:login>
      <table>
      <cms:error>
      <tr>
      <td colspan="2"><cms:trans>Invalid Login</cms:trans></td>
      </tr>
      </cms:error>
      
      <cms:use_email>
      <tr>
      <td><cms:trans>Email</cms:trans>:</td>
      <td><cms:email/></td>

      </tr>
      </cms:use_email>
      
      <cms:use_username>
      <tr>
      <td><cms:trans>Username</cms:trans>:</td>
      <td><cms:username/></td>
      </tr>
      </cms:use_username>
      
      <tr>
      <td><cms:trans>Password</cms:trans>:</td>
      <td><cms:password/></td>
      </tr>
      <tr>
      <td colspan='2' align='right'>
      <cms:submit/>
      </td>
      </tr>
      </table>
    </cms:login>
  </div>
  
  FEATURE
  
  
  def login_feature(data)
    webiva_feature(:login) do |c|
      c.expansion_tag 'logged_in' do |tag|
        data[:user]
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
      c.define_tag('login_form:email') { |tag| "name='cms_login[login]' id='cms_login_login'" }
      c.define_tag('login_form:username') { |tag| "name='cms_login[username]' id='cms_login_username'" }
      c.define_tag('login_form:password') { |tag|  "name='cms_login[password]' id='cms_login_password'" }
      
      c.define_tag('login_form:remember') { |tag| "type='checkbox' name='cms_login[remember]' value='1' id='cms_login_remember'" }

      c.form_for_tag('login','cms_login') do |t|
        data[:user] ? nil : data[:login_user]
      end

      c.value_tag('logged_in:profile_id') { |t| myself.user_class_id }

      c.field_tag('login:email',:size => 20,:field => 'login')
      c.field_tag('login:username',:size => 20)
      c.field_tag('login:password',:size => 20,:control => 'password_field')
      c.field_tag('login:remember',:control => 'check_box')
      c.button_tag('login:submit',:value => 'Login')
      
      
      c.expansion_tag('error') { |t| data[:error] }
      

      
      c.define_tag 'logged_in:name' do |tag|
        data[:user].first_name.blank? && data[:user].last_name.blank? ? '' : data[:user].name 
      end
      c.define_value_tag('logged_in:first_name'){ |tag| data[:user].first_name }
      c.define_value_tag('logged_in:last_name'){ |tag| data[:user].last_name }
      
      c.define_link_tag 'logged_in:logout' do |tag|
        if editor?
          { :href => 'javascript:void(0);' }
        else
          { :href => data[:logout_url] }
        end
      end
      
      c.define_expansion_tag('use_username') { |tag| data[:type] =='username' }
      c.define_expansion_tag('use_email') { |tag| data[:type] =='email'|| data[:type]=='both' }

      data[:options].login_features.each do |feature|
        feature.feature_instance.feature_tags(c,data[:feature])
      end
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
      c.form_for_tag('form',"email_list_#{paragraph.id}") { !data[:submitted] ? data[:email_list] : nil }
      
      c.define_form_error_tag('form:errors')
      
      c.define_form_field_tag('form:email')
      c.define_form_field_tag('form:zip')
      c.define_form_field_tag('form:first_name')
      c.define_form_field_tag('form:last_name')
      
      c.define_button_tag('form:button')
      
      c.expansion_tag('submitted') { |t| data[:submitted] }
    end
  end
  
  feature :view_account, :default_feature => <<-FEATURE
  <cms:user>
    <cms:name/>
  </cms:user>
  FEATURE

  def view_account_feature(data)
    webiva_feature(:view_account,data) do |c|
      c.expansion_tag('user') { |t| t.locals.user = data[:user] }
      c.user_details_tags('user') { |t| t.locals.user }
    end
  end
end
