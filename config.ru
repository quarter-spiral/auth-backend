Bundler.require

require 'auth-backend'

Auth::Backend::Apps.setup!

if ENV['RUNS_ON_METASERVER'] && Auth::Backend.env == 'development'
  require 'auth-backend/metaserver'
  Auth::Backend::Metaserver.setup!
end

$stdout.sync = true if ENV['QS_DEBUG_ENABLED']

require 'auth-backend/nasty_activerecord_fix'

require 'raven'
require 'qs/request/tracker/raven_processor'
Raven.configure do |config|
  config.tags = {'app' => 'auth-backend'}
  config.processors = [Raven::Processor::SanitizeData, Qs::Request::Tracker::RavenProcessor]
end
use Raven::Rack
use Qs::Request::Tracker::Middleware
run Auth::Backend::App.new