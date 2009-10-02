set :application, "webiva"
set :repository, "https://svn.cykod.com/#{application}/trunk"

role :web, "server.com"
role :app, "server.com"
role :db,  "server.com"

set :deploy_to, "/home/webiva"
set :user, "webiva"

