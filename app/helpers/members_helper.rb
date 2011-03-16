
module MembersHelper
  def display_segment_field(info, user, handler_data, field)
    if info[:partial]
      render :partial => info[:partial], :locals => {:info => info, :field => field, :handler_data => handler_data, :user => user}
    else
      h info[:handler].field_output(user, handler_data, field)
    end
  end

  def display_segment_fields(user)
    return unless @fields
    @fields.each do |field|
      field = field.to_sym
      info = UserSegment::FieldHandler.display_fields[field]
      next unless info
      yield field, display_segment_field(info, user, @handlers_data[info[:handler].to_s], field)
    end
  end
end
