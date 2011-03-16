
class Wizards::MembersSetup < WizardModel

  def self.structure_wizard_handler_info
    { :name => "Setup a Members Site",
      :description => 'This wizard will setup the pages for a members site.',
      :permit => "editor_structure_advanced",
      :url => self.wizard_url
    }
  end

  attributes :add_to_id => nil, :add_to_existing => true, :add_to_subpage => nil, :members_group_node_name => 'Members Site', :sidebar_login => true

  validates_format_of :add_to_subpage, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url', :allow_blank => true
  validates_presence_of :add_to_id
  validates_presence_of :members_group_node_name

  integer_options :add_to_id
  boolean_options :add_to_existing, :sidebar_login

  options_form(
               fld(:add_to, :add_page_selector),
               fld(:members_group_node_name, :text_field),
               fld(:sidebar_login, :check_boxes, :options => [['Add login to sidebar', true]])
               )

  def validate
    nd = SiteNode.find_by_id(self.add_to_id)
    if (self.add_to_existing.blank? && self.add_to_subpage.blank?)
      self.errors.add(:add_to," must have a subpage selected\nand add to existing must be checked")
    end
  end

  def run_wizard
    base_node = SiteNode.find(self.add_to_id)

    if self.add_to_existing.blank?
      base_node = base_node.add_subpage(self.add_to_subpage)
    end

    if self.sidebar_login
      self.root_node.push_modifier('framework') do |framework|
        framework.new_revision do |rv|
          rv.push_paragraph '/editor/auth', 'login', {}, :zone => 3
        end
      end
    end

    base_node.push_subpage(self.members_group_node_name, 'G') do |group_node|

      login_page_id = nil
      login_para = nil
      # Login
      group_node.push_subpage('login') do |nd, rv|
        login_page_id = nd.id
        # remove basic paragraph
        self.destroy_basic_paragraph(rv)
        login_para = rv.push_paragraph '/editor/auth', 'login'
      end

      # Registered
      success_page_id = nil
      group_node.push_subpage('registered') do |nd, rv|
        success_page_id = nd.id
        # Basic Paragraph
        rv.page_paragraphs[0].update_attribute :display_body, "<p>Thank you for registering.</p>"
      end

      # Register
      group_node.push_subpage('register') do |nd, rv|
        # remove basic paragraph
        self.destroy_basic_paragraph(rv)
        rv.push_paragraph '/editor/auth', 'user_register', {:success_page_id => success_page_id}
      end

      edit_account_page_id = nil
      # Members View Account
      group_node.push_subpage('members') do |members_node, rv|
        # Add members only lock
        members_node.push_modifier('lock') do |lock|
          lock.options.access_control = 'lock'
          lock.options.redirect = login_page_id
          lock.options.options = []
          lock.save
          UserClass.default_user_class.has_role('access', lock)
        end

        # remove basic paragraph
        self.destroy_basic_paragraph(rv)
        rv.push_paragraph '/editor/auth', 'view_account', nil

        # Members Edit Account
        members_node.push_subpage('edit-account') do |nd, rv|
          edit_account_page_id = nd.id
          # remove basic paragraph
          self.destroy_basic_paragraph(rv)
          rv.push_paragraph '/editor/auth', 'user_edit_account', {:success_page_id => members_node.id}
        end

        login_para.data[:success_page] = members_node.id
        login_para.save
      end

      # Missing Password
      group_node.push_subpage('missing-password') do |nd, rv|
        # remove basic paragraph
        self.destroy_basic_paragraph(rv)
        rv.push_paragraph '/editor/auth', 'missing_password', {:reset_password_page => edit_account_page_id, :email_template => self.get_missing_password_mail_template.id}
      end
    end
  end

  def get_missing_password_mail_template
    mail_template = MailTemplate.find_by_name 'Reset Password'
    return mail_template if mail_template

    MailTemplate.create :name => 'Reset Password', :subject => 'Reset Password', :language => 'en', :body_text => self.reset_password_mail_body_text, :body_html => self.reset_password_mail_body_html, :category => self.members_group_node_name, :template_type => 'site'
  end

  def reset_password_mail_body_html
    <<-BODY
<p>
<strong>Reset your Password</strong><br/>
<br/>
You can reset your password by following:<br/>
<a href="%%verification%%" target="_blank">%%verification%%</a>
</p>
    BODY
  end

  def reset_password_mail_body_text
    <<-BODY
Reset your Password

You can reset your password by following:
%%verification%%
    BODY
  end
end
