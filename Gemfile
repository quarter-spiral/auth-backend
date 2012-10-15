source 'https://rubygems.org'

# Specify your gem's dependencies in auth-backend.gemspec
gemspec

gem 'sinatra_warden', git: 'https://github.com/quarter-spiral/sinatra_warden.git'
gem 'songkick-oauth2-provider', git: 'https://github.com/quarter-spiral/oauth2-provider.git'

platform :ruby do
  gem 'thin'
  gem 'shotgun'
end

group :development do
  gem 'rake'
  gem 'sqlite3'
  gem 'rack-client'
  gem 'nokogiri'
end
