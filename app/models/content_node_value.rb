class ContentNodeValue < DomainModel

  belongs_to :content_node
  belongs_to :content_type

  named_scope :language, Proc.new { |lang| {  :conditions => { :language => lang }}}

  attr_accessor :excerpt

  cached_content

  def node
    self.content_node.node
  end

  def content_description(language)
    return '' unless self.content_node
    self.content_node.content_description language
  end

  def admin_url
    self.content_node.admin_url
  end

  def author
    self.content_node.author
  end

  def name
    self.title
  end


  class << self
    include ActionView::Helpers::TextHelper
  end

  def self.search(language, query, options)
    values = []
    total_results = 0
    with_scope(:find => {
               :conditions => ["language = ? AND content_nodes.published=1 AND MATCH (title,body) AGAINST (? IN BOOLEAN MODE)",language,query],
		 :include => [:content_node, :content_type],
		 :order => ["MATCH (title) AGAINST (",self.quote_value(query), ") DESC, MATCH (title,body) AGAINST (",self.quote_value(query), ") DESC"].join
	       }) do
      values = self.find(:all,options)
      values.each do |val|
        val.excerpt = excerpt(val.body,query)
        if val.excerpt.blank?
          val.excerpt = truncate(val.body,:length => 100)
        else
          val.excerpt = val.excerpt.split("\n").select { |str| str.downcase.include?(query.downcase) }.join(" ")
        end
        val.excerpt = highlight(val.excerpt,query.to_s.split(" ")).gsub("\n"," ")
      end
      options.delete(:limit)
      options.delete(:offset)
      total_results = self.count options
    end

    [values, total_results]
  end

  def self.search_items(ids)
    self.find(:all, :conditions => {:id => ids}, :include => [:content_node, :content_type])
  end
end
