class Webform::PageRenderer < ParagraphRenderer
  features '/webform/page_feature'

  paragraph :form
  paragraph :display

  def form
    @options = paragraph_options(:form)
    @captcha = WebivaCaptcha.new(self)

    result = renderer_cache([WebformForm, @options.webform_form_id], nil, :skip => @options.webform_form_id.blank? || request.post? || @options.captcha) do |cache|

      if @options.webform_form
        @result = WebformFormResult.new :webform_form_id => @options.webform_form.id, :end_user_id => myself.id, :ip_address => request.remote_ip
        @result.domain_log_session_id = session[:domain_log_session][:id] if session[:domain_log_session]

        param_str = 'results_' + paragraph.id.to_s
        if params[param_str]
          @result.assign_entry(params[param_str])
        end

        if params[param_str] && request.post? && ! editor?
          @captcha.validate_object(@result, :skip => ! @options.captcha)
          if @result.save
            @options.deliver_webform_results(@result)
            user = @result.connected_end_user ? @result.connected_end_user : myself
            run_triggered_actions('submitted', @result, user)
            @saved = true

            self.elevate_user_level(user, @options.user_level) if @options.user_level
            self.visiting_end_user_id = user.id if user && user.id

            return redirect_paragraph :site_node => @options.destination_page_id if @options.destination_page_id
          end
        end
      end

      cache[:title] = @options.webform_form.name if @options.webform_form
      cache[:output] = webform_page_form_feature
    end

    #set_title result.title, 'webform' unless result.title.blank?
    render_paragraph :text => result.output
  end

  def display
    @options = paragraph_options(:display)

    result = renderer_cache([WebformForm, @options.webform_form_id]) do |cache|
      cache[:output] = webform_page_display_feature
    end

    render_paragraph :text => result.output
  end
end
