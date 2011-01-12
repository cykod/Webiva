class NextSteps::PageFeature < ParagraphFeature

  feature :next_steps_page_view, :default_feature => <<-FEATURE
    View Feature Code...
  FEATURE

  def next_steps_page_view_feature(data)
    webiva_feature(:next_steps_page_view,data) do |c|
      # c.define_tag ...
    end
  end

end
