namespace :cms do
  desc "Run Webiva specs with RCov"
  RSpec::Core::RakeTask.new('rcov') do |t|
    t.rcov = true
    t.rcov_opts = %w{--rails --exclude gems\/,spec\/,features\/}
    t.pattern = ['spec/**/*_spec.rb', 'vendor/modules/*/spec/**/*_spec.rb']
  end
end
