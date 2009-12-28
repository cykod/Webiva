class ContentNodeValue < DomainModel

  belongs_to :content_node
  belongs_to :content_type

  named_scope :language, Proc.new { |lang| {  :conditions => { :language => lang }}}

  attr_accessor :excerpt

  def node
    self.content_node.node
  end

  def content_description(language)
    self.content_node.content_description language
  end

  def admin_url
    self.content_node.admin_url
  end

  def author
    self.content_node.author
  end

  def self.search(language, query, options)
    values = []
    total_results = 0
    with_scope(:find => {
               :conditions => ["language = ? AND MATCH (title,body) AGAINST (?)",language,query],
               :include => [:content_node, :content_type],
               :order => ["MATCH (title) AGAINST (",self.quote_value(query), ") DESC, MATCH (title,body) AGAINST (",self.quote_value(query), ") DESC"].join
               }) do
      values = self.find(:all,options)
      total_results = self.count options[:conditions]
    end

    [values, total_results]
  end

  def self.search_items(ids)
    self.find(:all, :conditions => {:id => ids}, :include => [:content_node, :content_type])
  end
end
