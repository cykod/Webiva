
class WebformFormResult < DomainModel

  include WebivaCaptcha::ModelSupport

  has_end_user :end_user_id, :name_column => :name
  belongs_to :webform_form
  belongs_to :domain_log_session

  validates_presence_of :webform_form_id

  content_node
  cached_content :update => [:webform_form]

  serialize :data

  named_scope :posted_after, lambda {|date| {:conditions => ["posted_at > ?", date]}}
  named_scope :posted_before, lambda {|date| {:conditions => ["posted_at < ?", date]}}
  named_scope :posted_between, lambda {|from, to| {:conditions => {:posted_at => (from..to)}}}

  def validate
    if self.webform_form
      errors.add(:data, 'is invalid') unless self.data_model.valid?
    end
  end

  def title
    self.webform_form.name
  end

  def triggered_attributes
    self.data_model.to_hash
  end

  def self.content_admin_url(node_id)
    node = self.find_by_id(node_id)
    node.content_admin_url if node
  end

  def content_admin_url
    { :controller => '/webform/manage', :action => 'result', :path => [ self.webform_form.id, self.id ] }
  end

  def content_node_body(lang, opts={})
    self.content_model.content_node_body(self.data_model, lang, opts)
  end

  def content_description(language) #:nodoc:
    "Webform"
  end

  def data_model
    return @data_model if @data_model
    return nil unless self.webform_form

    self.data ||= {}
    @data_model = self.content_model.create_data_model(self.data)
  end

  def connected_end_user
    self.data_model.connected_end_user
  end

  def before_validation_on_create
    if self.name.nil?
      self.name = self.end_user ? self.end_user.name : 'Anonymous'.t
    end
  end

  def before_create
    self.reviewed = false
    self.posted_at = Time.now
  end

  def before_save
    self.webform_form.webform_features(self)
  end

  def content_model
    self.webform_form.content_model
  end

  def assign_entry(values = {},application_state = {})
    self.content_model.assign_entry(self.data_model, values, application_state)
    self.data = self.data_model.to_h
    self.data_model
  end

  def send_result_to(email)
    MailTemplateMailer.deliver_message_to_address(email, self.email_subject, :html => self.email_message_html_body, :text => self.email_message_text_body)
  end

  def email_subject
    self.webform_form.name
  end

  def email_message_html_body
    @email_message_html_body ||= '<table><tr><td><strong>' + self.content_node_body(nil, :spacer => '</strong></td><td>', :separator => '</td></tr><tr><td><strong>') + '</td></tr></table>'
  end

  def email_message_text_body
    @email_message_text_body ||= self.content_node_body(nil, :separator => "\n")
  end

  def export_csv(writer, options={})
    if options[:header]
      writer << self.webform_form.content_model_fields.collect do |fld|
        fld.name
      end
    end

    writer << self.webform_form.content_model_fields.collect do |fld|
      fld.content_export(self.data_model)
    end
  end

  def webform_name
    self.webform_form.name
  end
end
