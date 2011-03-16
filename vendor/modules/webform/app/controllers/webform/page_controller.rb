class Webform::PageController < ParagraphController

  editor_header 'Webform Paragraphs'
  
  editor_for :form, :name => "Form", :feature => :webform_page_form, :triggers => [['Form Submitted', 'submitted']]
  editor_for :display, :name => "Display", :feature => :webform_page_display

  class FormOptions < HashModel
    attributes :webform_form_id => nil, :destination_page_id => nil, :email_to => nil, :captcha => false, :user_level => nil

    page_options :destination_page_id
    boolean_options :captcha
    integer_options :user_level

    validates_presence_of :webform_form_id

    options_form(
         fld(:webform_form_id, :select, :options => :webform_form_options),
         fld(:destination_page_id, :select, :options => :destination_page_options),
         fld(:email_to, :text_area, :rows => 4),
         fld(:captcha, :yes_no, :label => 'Require Captcha'),
         fld(:user_level, :select, :options => :user_level_options)
         )

    def self.destination_page_options
      [['--Select Destination Page--', nil]] + SiteNode.page_options
    end

    def self.webform_form_options
      WebformForm.select_options_with_nil
    end

    def webform_form
      @webform_form ||= WebformForm.find_by_id(self.webform_form_id)
    end

    def deliver_webform_results(results)
      return if self.email_to.blank?

      self.email_to.split("\n").each { |email|  email.strip }.select { |email| ! email.blank? }.each do |email|
        results.send_result_to(email)
      end
    end

    def options_partial
      "/application/triggered_options_partial"
    end

    def self.user_level_options
      [['--Select User Level--', nil]] + EndUser.user_level_select_options.select { |lvl| lvl[1] >= 3 && lvl[1] <= 5 }
    end
  end

  class DisplayOptions < HashModel
    attributes :webform_form_id => nil

    validates_presence_of :webform_form_id

    options_form(
         fld(:webform_form_id, :select, :options => :webform_form_options)
         )

    def self.webform_form_options
      WebformForm.select_options_with_nil
    end

    def webform_form
      @webform_form ||= WebformForm.find_by_id(self.webform_form_id)
    end
  end
end
