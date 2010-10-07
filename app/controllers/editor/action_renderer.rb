# Copyright (C) 2009 Pascal Rettig.

class Editor::ActionRenderer < ParagraphRenderer #:nodoc:all

  paragraph :triggered_action
  paragraph :html_headers, :cache => true
  paragraph :experiment
  paragraph :robots

  def robots
    return render_paragraph :text => 'Reconfigure Data Output' unless paragraph.data

    data = paragraph.data

    result = renderer_cache do |cache|
      output = ''
      SiteNode.find(:all, :conditions => {:index_page => [2,0]}, :order => 'index_page DESC, title').each do |node|
        if node.index_page == 2
          output += "Allow: #{node.node_path}\n"
        elsif node.index_page == 0
          output += "Disallow: #{node.node_path}\n"
        end
      end

      output = "User-agent: *\n#{output}" unless output.blank?
      output = "#{data[:extra]}\n#{output}" unless data[:extra].blank?
      cache[:output] = output
    end

    data_paragraph :disposition => '', :type => 'text/plain', :data => result.output
  end

  def triggered_action

    if !editor? && paragraph.view_action_count > 0
        paragraph.run_triggered_actions(myself,'view',myself)
    end
  
    if editor?
      render_paragraph :text => '[Triggered Actions]'
    else
      render_paragraph :nothing => true
    end
  end

  def experiment
    @options = paragraph_options(:experiment)

    if editor?
      render_paragraph :text => '[Experiment Success]'
    else
      require_js '/javascripts/experiment.js' unless @options.type == 'automatic'

      return render_paragraph :nothing => true unless session[:domain_log_visitor] && session[:cms_language]
      return render_paragraph :nothing => true if @options.type == 'manual'

      @exp_user = @options.experiment.get_user session

      if @exp_user && ! @exp_user.success?
        if @options.type == 'delayed'
          return render_paragraph :inline => "<script type=\"text/javascript\">WebivaExperiment.success(#{@options.experiment_id}, #{@options.delay_for.to_i});</script>\n"
        elsif @options.type == 'automatic'
          @exp_user.success!
        end
      end

      render_paragraph :nothing => true
    end
  end

  def html_headers

    @options = paragraph_options(:html_headers)

    if !editor?
      @options.css_files.each do |file|
        if(file =~ /^images\/(.*)$/)
          df = DomainFile.find_by_file_path("/#{$1}")
          file = df.url if df
        end
        require_css(file)
      end

      @options.js_files.each do |file|
        if(file =~ /^images\/(.*)$/)
          df = DomainFile.find_by_file_path("/#{$1}")
          file = df.url if df
        end
        require_js(file)
      end

      if !@options.html_header.blank?
        re = Regexp.new("(['\"\(\>])images\/([a-zA-Z0-9_\\-\\/. ]+?)(['\"\<\)])" ,Regexp::IGNORECASE | Regexp::MULTILINE)

        header = @options.html_header.gsub(re) do |mtch|
          pre = $1
          post = $3
          df = DomainFile.find_by_file_path("/#{$2}")
          df ? "#{pre}#{df.url}#{post}" : mtch[0]
        end
        include_in_head(header)
      end
    end

    render_paragraph :nothing => true

  end

 
end
