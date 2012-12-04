require "bundler/gem_tasks"

#require 'sinatra/activerecord/rake'
namespace :db do
  task :migrate do
    require 'auth-backend'
    Auth::Backend::Apps.setup_db!
    Auth::Backend::Apps.migrate_db!
  end

  task :rollback do
    require 'auth-backend'
    Auth::Backend::Apps.setup_db!
  end
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

task :default => :test
