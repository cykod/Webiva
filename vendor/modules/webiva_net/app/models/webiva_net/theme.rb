
class WebivaNet::Theme
  attr_accessor :title, :description, :author, :license, :guid, :link, :thumbnail, :bundle_url, :created_at

  def name; self.title; end

  def initialize(item={})
    %w(title description link guid thumbnail).each do |fld|
      self.send("#{fld}=", item[fld])
    end

    self.author = item['creator']
    self.created_at = item['pubDate']
    self.bundle_url = item['enclosure']['url'] if item['enclosure']
  end

  def self.find_by_guid(guid)
    self.themes.find { |theme| theme.guid == guid }
  end

  def self.themes
    local_cache_key = 'webiva_net_themes'
    return DataCache.local_cache(local_cache_key) if DataCache.local_cache(local_cache_key)

    url = WebivaNet::AdminController.module_options.themes_rss_url
    output, expires = DataCache.get_remote('WebivaNet::Theme', 'themes', url)
    unless output && expires > Time.now
      eater = Feed::GenericFeedEater.new url, 'xml', 5
      output = eater.parse
      return [] unless output

      DomainModel.remote_cache_put({ :remote_type => 'WebivaNet::Theme',
                                     :remote_target => 'themes',
                                     :display_string => url,
                                     :expiration => 1.hour}, output)
    end

    items = output['rss']['channel']['item']
    items = [items] unless items.is_a?(Array)
      
    themes = items.collect { |item| WebivaNet::Theme.new(item) }.sort { |a,b| a.name <=> b.name }

    DataCache.put_local_cache local_cache_key, themes
    themes
  end

   def self.download_folder
     DomainFile.find(:first,:conditions => "name = 'Downloads' and parent_id = #{DomainFile.themes_folder.id}") || DomainFile.create(:name => 'Downloads', :parent_id => DomainFile.themes_folder.id, :file_type => 'fld')
   end

  def bundle_file
    @bundle_file ||= DomainFile.create :filename => URI.parse(self.bundle_url), :parent_id => self.class.download_folder.id, :process_immediately => true
  end

  def install
    self.bundle_file
  end

  def thumbnail_tag
    src = self.thumbnail ? self.thumbnail['url'] : '/images/site/missing_thumb.gif'
    "<img src=\"#{src}\" width=\"128\"/>"
  end
end
