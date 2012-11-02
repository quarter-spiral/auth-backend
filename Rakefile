require "bundler/gem_tasks"

namespace :db do
  task :migrate do
    require 'auth-backend'
    Auth::Backend::Apps.setup!
  end

  task :rollback do
    require 'auth-backend'
    Auth::Backend::Apps.setup!
  end
end

require 'sinatra/activerecord/rake'
namespace :db do
  task :migrate do
    unless ENV['RACK_ENV']
      puts "Migrating test database"
      Auth::Backend::Apps.setup!
      out = `unset DATABASE_URL && bundle exec rake db:migrate RACK_ENV=test`
      raise "Migrating the test database failed" unless $?.exitstatus == 0
      puts out
    end
  end

  task :rollback do
    unless ENV['RACK_ENV']
      puts "Rolling back test database"
      Auth::Backend::Apps.setup!
      out = `unset DATABASE_URL && bundle exec rake db:rollback RACK_ENV=test`
      raise "Rolling back the test database failed" unless $?.exitstatus == 0
      puts out
    end
  end
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

task :default => :test
