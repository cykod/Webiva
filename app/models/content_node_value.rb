class ContentNodeValue < DomainModel


  belongs_to :content_node
  belongs_to :content_type

  named_scope :language, Proc.new { |lang| {  :conditions => { :language => lang }}}

end
