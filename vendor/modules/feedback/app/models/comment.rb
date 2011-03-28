# Copyright (C) 2009 Pascal Rettig.

class Comment < DomainModel

  include WebivaCaptcha::ModelSupport

  belongs_to :target, :polymorphic => true
  belongs_to :source, :polymorphic => true

  has_end_user :end_user_id, :name_column => :name

  belongs_to :rated_by_user, :foreign_key => 'rated_by_user_id', :class_name => 'EndUser'

  cached_content

  safe_content_filter({ :comment => :comment_html},:filter => :comment)

  before_validation :set_name, :on => :create

  validates_presence_of :name, :comment, :target_type, :target_id
  
  def self.with_rating(r); self.where('comments.rating >= ?', r); end
  def self.for_target(type, id); self.where('comments.target_type = ? AND comments.target_id = ?', type, id); end
  def self.order_by_posted(o=nil); o == 'newest' ? self.order('comments.posted_at DESC') : self.order('comments.posted_at'); end
  def self.for_source(type, id); self.where('comments.source_type = ? AND comments.source_id = ?', type, id); end
  def self.between(from, to); self.where(:posted_at => from..to); end

  before_save :update_posted_at

  def rating_icon(override=nil)
    override = rating unless override
    if override == 0
      'icons/table_actions/rating_none.gif'
    elsif override > 0
      'icons/table_actions/rating_positive.gif'
    else 
      'icons/table_actions/rating_negative.gif'
    end
  end

  def set_name
    return if self.name
    self.name = self.end_user ? self.end_user.name : 'Anonymous'.t
  end

  def update_posted_at
    self.posted_at = Time.now if self.posted_at.blank?
  end

  def self.content_node(scope=nil)
    scope ||= Comment
    scope.scoped :joins => 'join content_nodes on content_nodes.node_type = comments.target_type AND content_nodes.node_id = comments.target_id'
  end

  def content_node
    @content_node ||= ContentNode.first :conditions => {:node_type => self.target_type, :node_id => self.target_id}
  end

  def self.commented_scope(from, duration, opts={})
    scope = Comment.with_rating(0).between(from, from+duration)
    scope = Comment.content_node scope
    scope = scope.scoped(:select => 'count(content_nodes.id) as hits, content_nodes.id as target_id', :group => 'content_nodes.id')
    scope
  end

  def self.commented(from, duration, intervals, opts={})
    DomainLogGroup.stats('ContentNode', from, duration, intervals, :type => 'commented') do |from, duration|
      self.commented_scope from, duration, opts
    end
  end
end
