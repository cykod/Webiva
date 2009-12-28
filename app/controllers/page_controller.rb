# Copyright (C) 2009 Pascal Rettig.

require 'singleton' 

class PageController < ModuleAppController
  
  skip_before_filter :validate_module
  
  skip_before_filter :handle_page,:only => :paragraph
  skip_after_filter :process_logging, :only => :paragraph
  
  helper :paragraph

  def view
    session[:cms_language] = params[:language] if Configuration.languages.include?(params[:language])
    index
  end
  

  def paragraph
    
    revision = PageRevision.find(params[:page_revision],:conditions => ['revision_type IN ("real","old") AND revision_container_id=?',params[:site_node]])
    container = revision.revision_container
    para = revision.page_paragraphs.find(params[:paragraph])
    
    engine = SiteNodeEngine.new(container,:display => session[:cms_language], :path => [])
    
    @result = engine.run_paragraph(para,self,myself)
    
    if @result
      render :text => webiva_post_process_paragraph(render_paragraph(container.is_a?(SiteNode) ? container : container.site_node, revision, @result))
    else
      render :nothing => true
    end
  end
  
  def index
      # Handled by module app controller before filter
      render :action => 'index'
  end

  if RAILS_ENV == 'test'
    def set_test_renderer(rnd)
      @test_renderer = rnd
    end
    
    
    def renderer_test
      output = @test_renderer.send(@test_renderer.paragraph.display_type)   
      
      if output.is_a?(ParagraphRenderer::ParagraphOutput)
        render output.render_args
      else
        render :nothing => true
      end

    end  
    
    skip_before_filter :handle_page,:only => :renderer_test
    
  end
  

end
