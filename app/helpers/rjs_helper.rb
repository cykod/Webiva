module RjsHelper
  def set_rjs_content_type
    response.headers['Content-Type'] = 'text/javascript'
  end
end
