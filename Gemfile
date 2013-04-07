source 'https://rubygems.org'
source "https://user:We267RFF7BfwVt4LdqFA@privategems.herokuapp.com/"

# Specify your gem's dependencies in auth-backend.gemspec
gemspec

gem 'sinatra_warden', git: 'https://github.com/quarter-spiral/sinatra_warden.git'
gem 'songkick-oauth2-provider', git: 'https://github.com/quarter-spiral/oauth2-provider.git'

ruby "1.9.3"

group :production do
  platform :ruby do
    gem 'pg', '~> 0.15.0'
  end
end

gem 'thin'

group :development do
  gem 'rake'

  platform :ruby, :rbx do
    gem 'sqlite3'
  end

  platform :jruby do
    gem 'activerecord-jdbcsqlite3-adapter', :require => 'jdbc-sqlite3', :require =>'arjdbc'
  end

  gem 'rack-client'
  gem 'nokogiri'
  gem 'graph-backend', '~> 0.0.26'
  #gem 'graph-backend', path: '../graph-backend'
end
