
class FeedbackOutgoingPingback < DomainModel
  validates_presence_of :content_node_id, :target_uri
  belongs_to :content_node

  def self.add_pingback(node, link)
    return nil unless link =~ /http?:\/\/(.*?)(\/.*)/
    return nil if self.same_host?($1)
    return nil if self.find_by_content_node_id_and_target_uri(node.id, link)

    pingback = self.new :content_node_id => node.id, :target_uri => link
    pingback.send_pingback
    pingback.save
    pingback
  end

  def send_pingback
    begin
      source_uri = Configuration.domain_link(self.content_node.link)
      client = FeedbackPingbackClient.new(source_uri, target_uri)
      ok, param = client.send_pingback
      self.accepted = ok

      if ok
	self.status = param
	self.accepted = true
      else
	self.status_code = (param.faultCode || 0).to_i
	self.status = param.faultString
      end
    rescue Exception => e
      self.status = "#{e}"
    end

    self.sent_at = Time.now
  end

  def self.same_host?(target_host)
    domain = DomainModel.active_domain[:name]
    domain == target_host || ('www.' + domain) == target_host
  end
end
