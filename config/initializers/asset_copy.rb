

# Copy Assets over

Dir.glob("#{RAILS_ROOT}/vendor/modules/[a-z]*") do |file|
  if file =~ /\/([a-z_-]+)\/{0,1}$/
    mod_name = $1
    if File.directory?(file + "/public")
      FileUtils.mkpath("#{RAILS_ROOT}/public/components/#{mod_name}")
      FileUtils.cp_r(Dir.glob(file + "/public/*"),"#{RAILS_ROOT}/public/components/#{mod_name}/")
    end
  end
end

