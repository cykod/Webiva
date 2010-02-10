require 'hpricot'

module Feedback::PingbackSupport

  module ClassMethods
    def send_pingbacks(field, options={})
      after_save Proc.new { |obj| obj.send(:send_pingbacks, obj.resolve_argument(field), options) }, :if => options [:if]
      self.send(:include, Feedback::PingbackSupport::InstanceMethods)
    end
    
  end
  
  def self.append_features(mod) #:nodoc:
    super
    mod.extend Feedback::PingbackSupport::ClassMethods
  end
  

  module InstanceMethods
    def send_pingbacks(html, options={}) #:nodoc:
      node = ContentNode.find_by_node_type_and_node_id(self.class.to_s, self.id)
      return if node.nil? || node.link.blank?

      parser = Hpricot(html)
      (parser / :a).each do |link|
	FeedbackOutgoingPingback.add_pingback(node, link[:href]) if link[:href]
      end
    end
  end

end
