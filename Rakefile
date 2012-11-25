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

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

task :default => :test
