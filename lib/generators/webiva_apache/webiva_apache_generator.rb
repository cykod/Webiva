class WebivaApacheGenerator < Rails::Generator::Base
  attr_accessor :apache_user, :domain, :document_root, :system_path

  def manifest
    @domain = args.shift || 'mywebiva.com'
    @apache_user = args.shift

    @document_root = destination_path 'public'
    @system_path = destination_path 'public/system'

    record do |m|
      m.directory "config/apache"
      m.template 'virtual-host.conf', "config/apache/virtual-host.conf", :collision => :force
    end
  end

end
