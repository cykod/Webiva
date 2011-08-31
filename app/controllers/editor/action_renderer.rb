# Copyright (C) 2009 Pascal Rettig.

class Editor::ActionRenderer < ParagraphRenderer #:nodoc:all

  features '/editor/action_feature'

  paragraph :triggered_action
  paragraph :html_headers, :cache => true
  paragraph :experiment
  paragraph :robots
  paragraph :sitemap
  paragraph :server_error

  def robots
    return render_paragraph :text => 'Reconfigure Data Output' unless paragraph.data

    data = paragraph.data

    result = renderer_cache(nil, 'robots', :skip => true) do |cache|
      pages = ''
      SiteNode.find(:all, :conditions => {:index_page => [2,0], :node_type => 'P'}, :order => 'index_page DESC, title').each do |node|
        if node.index_page == 2
          pages += "Allow: #{node.node_path}\n"
        elsif node.index_page == 0
          pages += "Disallow: #{node.node_path}\n"
        end
      end

      pages = "User-agent: *\n#{pages}" unless pages.blank?

      sitemaps = SiteNode.find(:all, :conditions => {:node_type => 'M', :module_name => '/editor/sitemap'}).collect do |node|
        output = "Sitemap: #{Configuration.domain_link(node.node_path)}"
      end.join("\n")

      sitemaps ||= ''
      data[:extra] ||= ''

      output = ''
      output += "#{data[:extra]}\n\n" unless data[:extra].blank?
      output += "#{sitemaps}\n\n" unless sitemaps.blank?
      output += pages unless pages.blank?

      cache[:output] = output
    end

    data_paragraph :disposition => '', :type => 'text/plain', :data => result.output
  end

  def sitemap
    return render_paragraph :text => 'Reconfigure Data Output' unless paragraph.data

    data = paragraph.data

    result = renderer_cache(nil, 'sitemap') do |cache|
      @types = ContentType.find :all

      @detail_pages = @types.index_by(&:detail_site_node_url)
      @list_pages = @types.index_by(&:list_site_node_url)

      @urls = {}
      ContentNodeValue.find(:all, :conditions => {:search_result => true, :protected_result => false}, :include => :content_node).each do |value|
        next if value.link.blank? || value.content_node.nil? || value.content_node.node.nil?
        next if @detail_pages[value.link] && ! @list_pages[value.link]
        next if value.content_node.node_type == 'SiteNode' && ! value.content_node.node.can_index?
        @urls[value.link] = {:loc => value.link, :updated_at => value.updated_at}
      end

      cache[:output] = render_to_string(:partial => '/editor/action/sitemap', :locals => {:data => data, :urls => @urls})
    end

    data_paragraph :disposition => '', :type => 'text/xml', :data => result.output
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
      return render_paragraph :nothing => true unless @options.experiment

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

  def server_error
    @request_url = request.url
    if !editor?
      @server_error = self.controller.server_error
      return render_paragraph :feature => :editor_action_server_error if editor?
      return render_paragraph :nothing => true unless @server_error
      render_paragraph :feature => :editor_action_server_error, :status => 500
    else
      render_paragraph :text => 'Server Error Paragraph'
    end
  end
end
