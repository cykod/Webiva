# Copy Assets over
  
old_dir = Dir.pwd
Dir.chdir "#{Rails.root}/public/components"
Dir.glob("#{Rails.root}/vendor/modules/[a-z]*") do |file|
  if file =~ /\/([a-z0-9_-]+)\/{0,1}$/
    mod_name = $1
    if File.directory?(file + "/public") && ! File.exists?(mod_name)
      FileUtils.symlink("../../vendor/modules/#{mod_name}/public", mod_name)
    end
  end
end
Dir.chdir old_dir
