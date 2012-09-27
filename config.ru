Bundler.require

require 'auth-backend'

Auth::Backend::Apps.setup!

if ENV['RUNS_ON_METASERVER'] && Auth::Backend.env == 'development'
  require 'auth-backend/metaserver'
  Auth::Backend::Metaserver.setup!
end

run Auth::Backend::App.new
