module RjsHelper
  def set_rjs_content_type
    response.headers['Content-Type'] = 'text/javascript'
  end

  def set_json_content_type
    response.headers['Content-Type'] = 'application/json'
  end
end
