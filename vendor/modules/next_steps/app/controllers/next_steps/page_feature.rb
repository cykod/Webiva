class NextSteps::PageFeature < ParagraphFeature

  feature :next_steps_page_view, :default_feature => <<-FEATURE
    <cms:steps>
      <div class="steps">
        <cms:step>
          <a href="<cms:step:page/>">
          
          </a>
        </cms:step>
      </div>
    </cms:steps>
    <cms:no_steps>Invalid Next Steps</cms:no_steps>
  FEATURE

  def next_steps_page_view_feature(data)
    webiva_feature(:next_steps_page_view, data) do |c|
      c.loop_tag('step') { |t| data[:steps] }
      c.define_expansion_tag('')
      
      
      
    #   c.expansion_tag('steps') {  |t| data[:steps] }
    #   c.expansion_tag('responded') {  |t| data[:state] == 'responded'}
    #   c.value_tag('responded:graph') do |t|
    #     data[:steps].results_graph(data[:options].graph_width, data[:options].graph_height)
    #   end
    #   c.h_tag('question') { |t| data[:steps].question }
    #   c.field_tag('form:response',
    #     :control => :radio_buttons,
    #     :separator => '<br/>') { |t| data[:steps].answer_options }
    #   c.submit_tag('form:submit',:default => 'Submit')
    # end
  end


  def next_steps_page_view_feature(data)
    webiva_feature(:next_steps_page_view,data) do |c|
      # c.define_tag ...
    end
  end

end
