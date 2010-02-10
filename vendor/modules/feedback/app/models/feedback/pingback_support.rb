require 'hpricot'

module Feedback::PingbackSupport
  def run_pingbacks(field, parameters={}) #:nodoc:
    if field.instance_of?(Symbol)
      parameters.merge!(:field => field)
    else
      parameters.merge!(:html => field)
    end
    self.run_worker(:send_pingbacks, parameters)
  end

  def send_pingbacks(options={}) #:nodoc:
    html = options.delete(:html)
    if html.blank?
      field = options.delete(:field)
      html = self.send(field) if field
    end

    return if html.blank?

    node = ContentNode.find_by_node_type_and_node_id(self.class.to_s, self.id)
    return if node.nil? || node.link.blank?

    parser = Hpricot(html)
    (parser / :a).each do |link|
      FeedbackOutgoingPingback.add_pingback(node, link[:href]) if link[:href]
    end
  end
end
