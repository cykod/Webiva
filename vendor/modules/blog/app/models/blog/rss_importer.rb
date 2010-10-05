require 'nokogiri'

class Blog::RssImporter
  attr_accessor :xml, :blog, :images, :folder, :error

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper

  def initialize
    self.images = {}
  end

  def folder
    @folder ||= DomainFile.push_folder self.blog.name
  end

  def import_feed(url)
    begin
      res = DomainFile.download url
      self.xml = res.body.to_s
      true
    rescue
      self.error = 'RSS feed download failed'
      false
    end
  end

  def import
    doc = Nokogiri::XML self.xml
    unless doc
      self.error = 'RSS feed is invalid'
      return false
    end

    channel = doc.css('channel').first
    unless channel
      self.error = 'RSS feed is invalid'
      return false
    end

    channel.css('item').each do |item|
      self.create_post item
    end

    true
  end

  def push_category(name)
    return nil if name.downcase == 'uncategorized'
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

  def create_post(item)
    title = item.css('title').text
    body = item.css('description').text
    author = item.css('dc:creator').text
    author = item.css('creator').text if author.blank?
    author = item.css('author').text if author.blank?

    pubDate = item.css('pubDate').text
    pubDate = nil if pubDate.blank?
    pubDate = pubDate ? Time.parse(pubDate) : Time.now
    return if body.blank? || title.blank?

    if author
      author.gsub! /[^\s]+@[^\s]+/, '' # remove the email address
      author.gsub! /[^ a-zA-Z0-9\-]/, '' # remove any non name characters
      author.strip!
      author = nil if author.blank?
    end

    post = self.blog.blog_posts.create :body => self.parse_body(body), :author => author, :title => title, :status => 'published', :published_at => pubDate, :disallow_comments => false, :created_at => pubDate, :updated_at => pubDate

    return unless post.id

    item.css('category').each do |category|
      cat = self.push_category(category.text.strip)
      Blog::BlogPostsCategory.create(:blog_post_id => post.id, :blog_category_id => cat.id) if cat
    end

    post
  end
end
