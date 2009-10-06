set :application, "webiva"
set :scm, :git
set :repository, "git://github.com/cykod/Webiva.git"

set :module_repository, "git://github.com/cykod/"


role :web, "server.com"
role :app, "server.com"
role :db,  "server.com"

set :deploy_to, "/home/webiva"
set :user, "webiva"

