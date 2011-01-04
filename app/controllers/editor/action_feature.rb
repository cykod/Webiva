
class Editor::ActionFeature < ParagraphFeature

  feature :editor_action_server_error, :default_feature => <<-FEATURE
  <cms:auth_error>
    <h1>Error</h1>
    <p>The form you submitted expired, <cms:request_link>click here</cms:request_link> to go back</p>
  </cms:auth_error>
  <cms:not_auth_error>
    <h1>Error</h1>
    <p>500 Server Error, <cms:request_link>click here</cms:request_link> to go back</p>
  </cms:not_auth_error>
  FEATURE

  def editor_action_server_error_feature(data)
    webiva_feature(:editor_action_server_error,data) do |c|
      c.link_tag('request') { |t| data[:request_url] }
      c.expansion_tag('auth_error') { |t| data[:server_error].is_a?(ActionController::InvalidAuthenticityToken) }
    end
  end
end
