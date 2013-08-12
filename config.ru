Bundler.require

require 'auth-backend'

Auth::Backend::Apps.setup!

if ENV['RUNS_ON_METASERVER'] && Auth::Backend.env == 'development'
  require 'auth-backend/metaserver'
  Auth::Backend::Metaserver.setup!
end

$stdout.sync = true if ENV['QS_DEBUG_ENABLED']

require 'auth-backend/nasty_activerecord_fix'

use Qs::Request::Tracker::Middleware
run Auth::Backend::App.new