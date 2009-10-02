require 'fileutils'
require 'active_record'

namespace "cms" do 

desc "Run a domain task"
task :website_export => [:environment] do |t|

  unless ENV['DOMAIN_ID']
    raise 'USAGE: rake cms:website_export DOMAIN_ID=[DOMAIN_ID]'
  end

  DomainModel.activate_domain(ENV['DOMAIN_ID'].to_i) 
  
  dmn = Domain.find(ENV['DOMAIN_ID'].to_i)
  backup_dir =  Time.now.strftime('%Y%m%d%H%M%S') + "_export_" + dmn.database
  dir = "#{RAILS_ROOT}/backup/#{backup_dir}"
  FileUtils.mkpath(dir)
  
  SiteNode.find(:all,:conditions => 'node_type = "P"').each do |path|
    FileUtils.mkpath(dir + path.node_path)
    print("Exporting: #{path.node_path}...")
    `wget -O #{dir}#{path.node_path}/index.html #{dmn.name}#{path.node_path}`
    print("Done\n")
  end

  FileUtils.mkpath(dir + "/system/storage/#{dmn.file_store}")
  `cp -r  #{RAILS_ROOT}/public/system/storage/#{dmn.file_store}/* #{dir}/system/storage/#{dmn.file_store}`

  FileUtils.mkpath(dir + "/system/private/#{dmn.file_store}")
  `cp -r  #{RAILS_ROOT}/public/system/private/#{dmn.file_store}/* #{dir}/system/private/#{dmn.file_store}`

  FileUtils.mkpath(dir + "/stylesheet/")
  SiteTemplate.find(:all,:conditions => 'parent_id IS NULL').each do |tpl|
    `wget -O #{dir}/stylesheet/#{tpl.id}.css #{dmn.name}/stylesheet/#{tpl.id}.css`
  end
  
end

end
