
class Blog::WordpressImporter
  attr_accessor :xml, :blog, :images, :folder, :error, :import_comments, :import_pages

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper

  def initialize
    self.images = {}
    self.import_pages = true
    self.import_comments = true
  end

  def folder
    @folder ||= DomainFile.push_folder self.blog.name
  end

  def import_file(file)
    file = file.filename if file.is_a?(DomainFile)
    File.open(file, 'r') { |f| self.xml = f.read }
    true
  end

  def import_site(url, username, password)
    service = Blog::WordpressWebService.new url, username, password
    unless service.login
      self.error = service.error
      return false
    end

    self.xml = service.export
    unless self.xml
      self.error = service.error
      return false
    end

    true
  end

  def parse
    begin
      Hash.from_xml self.xml.gsub('excerpt:encoded>', 'excerpt>').gsub(/<category domain="tag"(.*?)<\/category>/, '<tag\1</tag>').gsub(/<\/?atom:.*?>/, '')
    rescue
    end
  end

  def import
    xml_data = self.parse
    unless xml_data
      self.error = 'WordPress file is invalid'
      return false
    end

    unless xml_data['rss'] && xml_data['rss']['channel']
      self.error = 'WordPress file is invalid'
      return false
    end

    categories = {}
    blog_categories = xml_data['rss']['channel']['category']
    if blog_categories
      blog_categories = [blog_categories] unless blog_categories.is_a?(Array)
      blog_categories.each do |category|
        cat = self.push_category(category)
        next unless cat
        categories[category['cat_name']] = cat
      end
    end

    items = xml_data['rss']['channel']['item']
    if items
      items = [items] unless items.is_a?(Array)
      items.each do |item|
        if item['post_type'] == 'post'
          self.create_post categories, item
        elsif item['post_type'] == 'page'
          self.create_page item
        end
      end
    else
      self.error = 'WordPress file has no posts to import'
      return false
    end

    true
  end

  def push_category(opts={})
    name = opts['cat_name']
    return nil if name == 'Uncategorized'
    return nil if name.blank?
    self.blog.blog_categories.find_by_name(name) || self.blog.blog_categories.create(:name => name)
  end

  def parse_body(body)
    body.gsub!(/(\[caption.*?\])(.*?)\[\/caption\]/) do |match|
      content = $2
      div = $1.sub('[caption', '<div').sub(/\]$/, '>').sub('align="', 'class="wp-caption ')

      caption = ''
      if div =~ /caption=(["'])([^\1]+)\1/
        caption = $2
      end

      "#{div}#{content}<p class=\"wp-caption-text\">#{caption}</p></div>"
    end

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
    return if self.blog.blog_posts.find_by_permalink item['post_name']

    status = item['status'] == 'publish' ? 'published' : 'draft'
    disallow_comments = item['comment_status'] == 'open' ? false : true
    published_at = Time.now
    begin
      published_at = Time.parse(item['pubDate'])
    rescue
    end

    posted_at = Time.now
    begin
      posted_at = Time.parse(item['post_date'])
    rescue
    end

    post = self.blog.blog_posts.create :body => self.parse_body(body), :author => item['creator'], :title => item['title'], :published_at => published_at, :status => status, :disallow_comments => disallow_comments, :permalink => item['post_name'], :created_at => posted_at, :preview => self.parse_body(item['excerpt'])

    return unless post.id

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
    return unless self.import_comments
    return if comment['comment_content'].blank?
    user = comment['comment_author_email'].blank? ? nil : EndUser.push_target(comment['comment_author_email'], :name => comment['comment_author'])
    rating = comment['comment_approved'] == "1" ? 1 : 0

    posted_at = Time.now
    begin
      posted_at = Time.parse(comment['comment_date'])
    rescue
    end

    Comment.create :target => post, :end_user_id => user ? user.id : nil, :posted_at => posted_at, :posted_ip => comment['comment_author_IP'], :name => comment['comment_author'], :email => comment['comment_author_email'], :comment => comment['comment_content'], :rating => rating
  end

  def create_page(item)
    return unless self.import_pages
    body = item['encoded']
    return if body.blank?

    path = nil
    begin
      uri = URI.parse(item['link'])
      path = uri.path.sub(/^\//, '').sub(/\/$/, '')
    rescue
    end

    return unless path

    node_path = nil
    parent = SiteVersion.current.root_node
    path.split('/').each do |node_path|
      node_path = '' if node_path == 'home'
      parent = parent.push_subpage(node_path)
    end

    parent.push_subpage(node_path) do |nd, rv|
      rv.title = item['title']
      # Basic Paragraph
      rv.push_paragraph(nil, 'html') do |para|
        para.display_body = self.parse_body(body)
      end
    end
  end
end
