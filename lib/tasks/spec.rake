Rake::Task["db:abort_if_pending_migrations"].clear
Rake::Task["db:test:prepare"].clear

namespace :db do
  task :abort_if_pending_migrations do
    raise "WTFER?"
  end
end

namespace :db do
    namespace :test do
          task :prepare do
            # Stub out for MongoDB
          end
    end
end
