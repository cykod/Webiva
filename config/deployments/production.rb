set :application, "webiva"
set :scm, :git
set :repository, "git://github.com/westarete/Webiva.git"

set :module_repository, "git://github.com/cykod/"

role :web, "shiitake.westarete.com", "alexander.westarete.com"
role :app, "shiitake.westarete.com", "alexander.westarete.com"
role :db,  "shiitake.westarete.com", "alexander.westarete.com"

set :deploy_to, "/var/www/domains/webiva.production.westarete.com"

ssh_options[:port] = 22222

namespace :webiva do
  task :make_public_writeable do
    run "sudo chown -Rh passenger #{deploy.release_path}/public/components"
  end
end
after 'webiva:server_deploy', 'webiva:make_public_writeable'
