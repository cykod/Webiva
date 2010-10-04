
class Editor::ContentController < ParagraphController #:nodoc:all

  # Editor for authorization paragraphs
  editor_header "Content Paragraphs", :paragraph_content

  editor_for :recent_content, :name => 'Recent Content', :feature => :recent_content

  class RecentContentOptions < HashModel
    attributes :content_type_ids => [], :count => 10, :order_by => 'newest'
    
    integer_array_options :content_type_ids
    integer_options :count
    validates_numericality_of :count

    options_form(
           fld(:count,:text_field,:label => "Number to show"),
           fld(:order_by,:select,:options => :order_by_options,:label => "Display"),
           fld(:content_type_ids,:ordered_array,:options => :content_type_options,
               :label => "Limit by Content Type",
               :description => "Paragraph will show all updated content or only specific types")
                )

    def content_type_options
      ContentType.select_options
    end

    def order_by_options
      [['Newest', 'newest'], ['Recently Updated', 'updated']]
    end

    def order
      if self.order_by == 'updated'
	'updated_at DESC'
      else
	'created_at DESC'
      end
    end
  end

end
