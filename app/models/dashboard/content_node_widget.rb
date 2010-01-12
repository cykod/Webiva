

class Dashboard::ContentNodeWidget < Dashboard::WidgetBase

  widget :updates, :name => "Display Updated Content", :permit => 

  def updates
    
  end

  class UpdatesOptions < HashModel
    attributes :content_type_ids => [], :title => "Updated Content"
    
    integer_array_options :content_type_ids
  end

end
