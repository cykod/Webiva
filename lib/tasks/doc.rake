if ENV['TEMPLATE'] == 'darkfish'
   gem 'darkfish-rdoc'
   require 'darkfish-rdoc'
end

namespace :doc do
  desc "Generate documentation for the application. Set custom template TEMPLATE=template requires darkfish-rdoc gem to use template=darkfish"
  Rake::RDocTask.new("webiva") { |rdoc|
    rdoc.rdoc_dir = 'doc/app'
    rdoc.title    = "Webiva API Documentation"
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.options << '--charset' << 'utf-8'
  
      
    
    rdoc.rdoc_files.include('doc/README_FOR_APP')
    rdoc.rdoc_files.include('app/**/*.rb')
    rdoc.rdoc_files.exclude("lib/generators/*")
    rdoc.rdoc_files.include('lib/**/*.rb')

    if ENV['TEMPLATE']
    rdoc.options += [
       '-f',ENV['TEMPLATE']
    ]
    end

  }


end
