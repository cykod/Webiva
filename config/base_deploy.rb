load 'deploy'
# =============================================================================
# TASKS
# =============================================================================
# Define tasks that run on all (or only some) of the machines. You can specify
# a role (or set of roles) that each task should be executed on. You can also
# narrow the set of servers to a subset of a role by specifying options, which
# must match the options given for the servers to select (like :primary => true)
namespace :webiva do 
  

  desc "Webiva Configuration Linking"
  task :config do
        run "rm -rf #{deploy.release_path}/config/sites"
        run "ln -s  #{deploy.shared_path}/config/sites #{deploy.release_path}/config/sites"
        run "ln -s #{deploy.shared_path}/config/backup.yml #{deploy.release_path}/config/backup.yml; true"
        run "ln -s #{deploy.shared_path}/config/cms.yml #{deploy.release_path}/config/cms.yml"
        run "ln -s #{deploy.shared_path}/config/cms_migrator.yml #{deploy.release_path}/config/cms_migrator.yml"
        run "ln -s #{deploy.shared_path}/config/defaults.yml #{deploy.release_path}/config/defaults.yml"
        run "ln -s #{deploy.shared_path}/config/backgroundrb.yml #{deploy.release_path}/config/backgroundrb.yml"
        run "ln -s #{deploy.shared_path}/config/mongrel_cluster.yml #{deploy.release_path}/config/mongrel_cluster.yml"
  end


  desc "Custom Webiva Deployment"
  task :server_deploy do
    transaction do
	    deploy.update_code
            modules_install     
	    deploy.web.disable
	    config
      run "cd #{deploy_to}/current; ./script/backgroundrb stop; true"
	    deploy.symlink
	    run "cd #{deploy.release_path}; rake -f #{deploy.release_path}/Rakefile cms:migrate_system_db"
	    run "cd #{deploy.release_path}; rake -f #{deploy.release_path}/Rakefile cms:migrate_domain_dbs"
	    run "cd #{deploy.release_path}; rake -f #{deploy.release_path}/Rakefile cms:migrate_domain_components"
      run "cd #{deploy_to}/current; ./script/backgroundrb start; true"
	    sudo "nohup /etc/init.d/memcached restart"
    end

   deploy.restart
   deploy.web.enable
  end


  desc "Webiva Module deployment"
  task :modules_install do
	(webiva_modules||[]).each do |mod|
          execute = []
          execute << "cd #{deploy.release_path}/vendor/modules"
          execute << "git clone #{module_repository}:webiva-#{mod} #{mod}"
          run execute.join(" && ")
        end
  end 


  desc "Webiva Setup Config"
  task :setup do 
    transaction do
      top.deploy.update_code
      run "mkdir #{deploy.shared_path}/config; true"
      run "cp #{deploy.release_path}/config/cms.yml.example #{deploy.shared_path}/config/cms.yml; true"
      run "cp #{deploy.release_path}/config/backup.yml.example #{deploy.shared_path}/config/backup.yml; true"
      run "cp #{deploy.release_path}/config/cms_migrator.yml.example #{deploy.shared_path}/config/cms_migrator.yml; true"
      run "cp #{deploy.release_path}/config/backgroundrb.yml.example #{deploy.shared_path}/config/backgroundrb.yml; true"
      run "cp #{deploy.release_path}/config/defaults.yml.example #{deploy.shared_path}/config/defaults.yml; true"
      run "cp #{deploy.release_path}/config/mongrel_cluster.yml.example #{deploy.shared_path}/config/mongrel_cluster.yml; true"
      run "mkdir #{deploy.shared_path}/config/sites; true"
      config
      deploy.symlink
    end
  end

end

#set :deploy_via, :export
set :runner, nil
set :mongrel_conf, "#{deploy_to}/current/config/mongrel_cluster.yml"

namespace :deploy do
  task :restart do
    run "cd #{deploy_to}/current; mongrel_rails cluster::restart"
  end
end


