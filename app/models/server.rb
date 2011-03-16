
class Server < SystemModel
  validates_presence_of :hostname

  @@server_name = nil
  def self.server_name
    return @@server_name if @@server_name

    if File.exists?("#{RAILS_ROOT}/config/server.yml")
      @@server_name = YAML.load_file("#{RAILS_ROOT}/config/server.yml")['server']['name']
    else
      @@server_name = 'localhost'
    end

    @@server_name
  end

  @@server_info = nil
  def self.server_info
    @@server_info ||= self.fetch_server_info
  end

  def self.server_id
    self.server_info[:id]
  end

  def self.fetch_server_info
    begin
      info = Server.find_by_hostname Server.server_name
      info ? info.attributes.symbolize_keys : {:hostname => Server.server_name, :port => 80}
    rescue Mysql::Error => e
      {:hostname => Server.server_name, :port => 80}
    end
  end

  def self.create_standalone
    server = self.create :hostname => Server.server_name, :port => port, :master_db => true, :domain_db => true, :slave_db => false, :web => true, :memcache => true, :starling => true, :workling => true, :cron => true
    self.server_info = server.attributes.symbolize_keys
    server
  end

  def link(url)
    host = self.port == 80 ? self.hostname : "#{self.hostname}:#{self.port}"
    "http://#{host}#{url}"
  end

  def fetch(url)
    Net::HTTP.get_response(URI.parse(self.link(url)))
  end

  def self.send_to_all(url, opts={})
    Server.find(:all).each do |server|
      # only web and workling servers have a web server running
      next unless server.web || server.workling
      next if opts[:except] && opts[:except].include?(server.id)
      response = server.fetch(url)
      logger.error "failed to fetch #{url} from #{server.hostname}" unless Net::HTTPSuccess === response
    end
  end
end
