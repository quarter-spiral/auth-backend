require 'newrelic_rpm'
require 'new_relic/agent/instrumentation/rack'
require 'ping-middleware'

module Auth::Backend
  class App
    class NewRelicMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      end
      include NewRelic::Agent::Instrumentation::Rack
    end

    def initialize(options = {})
      @app = Rack::Builder.new do
        map '/assets' do
          use Rack::Static, :urls => ["/stylesheets", "/images", "/javascripts", "/ico"], :root => "lib/auth-backend/apps/assets"
        end

        use Rack::Session::Cookie, secret: ENV['QS_COOKIE_SECRET'] || 'some-secret', key: 'qs_auth_backend_session', :expire_after => 2592000

        use NewRelicMiddleware
        use Ping::Middleware

        if options[:test]
          puts "!!***** WARNING - SECURITY IS AT STAKE! YOU HAVE ENABLED THE TEST MODE *****!!"
          map '/_tests_' do
            run Auth::Backend::Apps::Test
          end
        end

        use Warden::Manager do |manager|
          manager.default_strategies :password
          manager.failure_app = Auth::Backend::Apps::Authentication
        end

        map '/admin' do
          run Auth::Backend::Apps::Admin
        end

        map '/api/v1' do
          run Auth::Backend::Apps::API
        end

        run Auth::Backend::Apps::Authentication
      end
    end

    def call(env)
      result = @app.call(env)
      if env['omniauth.error']
        [302, {'Content-Type' => 'text/plain', 'Location' => '/auth/denied'}, ['']]
      else
        result
      end
    end
  end
end
