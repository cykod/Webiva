
class Blog::WordpressImporter
  attr_accessor :xml, :blog, :images, :folder

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper

  def initialize
    self.images = {}
  end

  def folder
    @folder ||= DomainFile.push_folder self.blog.name
  end

  def parse
    begin
      Hash.from_xml self.xml.gsub('excerpt:encoded>', 'excerpt>').gsub(/<category domain="tag"(.*?)<\/category>/, '<tag\1</tag>')
    rescue
    end
  end

  def import
    xml_data = self.parse
    return unless xml_data

    categories = {}
    blog_categories = xml_data['rss']['channel']['category']
    blog_categories = [blog_categories] unless blog_categories.is_a?(Array)
    blog_categories.each do |category|
      cat = self.push_category(category)
      next unless cat
      categories[category['cat_name']] = cat
    end

    items = xml_data['rss']['channel']['item']
    items = [items] unless items.is_a?(Array)
    items.each do |item|
      if item['post_type'] == 'post'
        self.create_post categories, item
      end
    end
  end

  def push_category(opts={})
    name = opts['cat_name']
    return nil if name == 'Uncategorized'
    return nil if name.blank?
    self.blog.blog_categories.find_by_name(name) || self.blog.blog_categories.create(:name => name)
  end

  def parse_body(body)
    body.gsub!(/src=("|')([^\1]+?)\1/) do |match|
      quote = $1
      src = $2
      file = nil
      file = self.folder.add(src) if src =~ /^http/
      if file
        self.images[src] = file
        "src=#{quote}#{file.editor_url}#{quote}"
      else
        match
      end
    end

    self.images.each do |src, file|
      body.gsub! src, file.editor_url
    end

    simple_format body
  end

  def create_post(categories, item={})
    body = item['encoded']
    return if body.blank?
    status = item['status'] == 'publish' ? 'published' : 'draft'
    disallow_comments = item['comment_status'] == 'open' ? false : true
    post = self.blog.blog_posts.create :body => self.parse_body(body), :author => item['creator'], :title => item['title'], :status => 'published', :published_at => Time.parse(item['pubDate']), :status => status, :disallow_comments => disallow_comments, :permalink => item['post_name'], :created_at => Time.parse(item['post_date_gmt']), :preview => self.parse_body(item['excerpt'])

    post_categories = item['category']
    post_categories = [post_categories] unless post_categories.is_a?(Array)
    post_categories.uniq.each do |cat|
      next unless categories[cat]
      Blog::BlogPostsCategory.create :blog_post_id => post.id, :blog_category_id => categories[cat].id
    end

    comments = item['comment']
    if comments
      comments = [comments] unless comments.is_a?(Array)
      comments.each do |comment|
        self.create_comment post, comment
      end
    end

    if item['tag']
      tags = item['tag']
      tags = [tags] unless tags.is_a?(Array)
      post.add_tags tags.join(',')
    end

    post
  end

  def create_comment(post, comment)
    return if comment['comment_content'].blank?
    user = comment['comment_author_email'].blank? ? nil : EndUser.push_target(comment['comment_author_email'], :name => comment['comment_author'])
    rating = comment['comment_approved'] == "1" ? 1 : 0
    Comment.create :target => post, :end_user_id => user ? user.id : nil, :posted_at => Time.parse(comment['comment_date_gmt']), :posted_ip => comment['comment_author_IP'], :name => comment['comment_author'], :email => comment['comment_author_email'], :comment => comment['comment_content'], :rating => rating
  end
end
