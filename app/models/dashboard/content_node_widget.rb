

class Dashboard::ContentNodeWidget < Dashboard::WidgetBase

  widget :updates, :name => "Display Updated Content", :title => "Updated Site Content"

  def updates
    conditions = options.content_type_ids.length > 0 ? {  :content_type_id => options.content_type_ids } : nil
    nodes = ContentNode.find(:all,:conditions => conditions, :limit => options.count, :order => "updated_at DESC" )
    
    render_widget :partial => '/dashboard/content_node_widget', :locals => {  :content_nodes => nodes, :options => options }
  end

  class UpdatesOptions < HashModel
    attributes :content_type_ids => [], :title => "Updated Content", :count => 10, :show_description => true
    
    boolean_options :show_description
    integer_array_options :content_type_ids
    integer_options :count
    validates_numericality_of :count

    options_form(
           fld(:count,:text_field,:label => "Number to show"),
           fld(:show_description,:radio_buttons, :options => :yes_no,
               :description => "Show description of type of content below title?"),
           fld(:content_type_ids,:ordered_array,:options => :content_type_options,
               :label => "Limit by Content Type",
               :description => "Widget will show all updated content or only specific types")
                )

    def content_type_options
      ContentType.select_options
    end
    def yes_no
      [["Yes".t,true],["No".t,false]]
    end
  end

end
