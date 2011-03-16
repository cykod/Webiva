

module ModuleAppHelper


  # Renders the output object of SiteNodeEngine given the page SiteNode
  # and the SiteNodeEngine::PageOutput object
  def render_output(page,output_obj,&block)
    raise "Not a PageOutput" unless output_obj.is_a?(SiteNodeEngine::PageOutput)
    output = ''
    output_obj.html  do |blk| 
      if blk.is_a?(String) 
        output += webiva_post_process_paragraph(blk)
      elsif blk.is_a?(Hash) 
        blk[:paragraphs].each do |para| 
          if para.is_a?(String) 
            output << webiva_post_process_paragraph(para)
          elsif para.is_a?(ParagraphRenderer::ParagraphOutput) && para.rnd.is_a?(Editor::AppRenderer)
            concat(output)
            output = ''
            yield
          else 
            if output_obj.lightweight
              output << webiva_post_process_paragraph(render_paragraph page, output_obj.revision,para)
            else
              para_id = para.is_a?(ParagraphRenderer::ParagraphOutput) ? "id='cmspara_#{para.rnd.paragraph.id}'" : ""
              output << "<div class='paragraph' #{para_id}>#{webiva_post_process_paragraph(render_paragraph page, output_obj.revision, para)}</div>"
            end
          end 
        end 
      end 
    end
    if block_given?
      concat(output)
    else
      output       
    end
  end 


end
