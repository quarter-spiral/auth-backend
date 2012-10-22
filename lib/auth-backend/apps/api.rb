require 'uri'

module Auth::Backend
  module Apps
    class API < Sinatra::Base
      register Base

      helpers do
        def auth
          @auth ||= Rack::Auth::Basic::Request.new(env)
        end

        def ensure_authentication!
          unless auth.provided?
            error(403, {error: 'Authenticate with HTTP basic auth!'}.to_json)
          end
        end
      end

      before do
        content_type :json
      end

      get '/me' do
        token = Songkick::OAuth2::Provider.access_token(nil, [], env)

        if token.valid?
          token.owner.private_info.to_json
        else
          status 403
          {error: 'Not authorized!'}.to_json
        end
      end

      get '/verify' do
        token = Songkick::OAuth2::Provider.access_token(nil, [], env)
        status token.valid? ? 200 : 403
        ''
      end

      post '/token' do
        ensure_authentication!
        username, password = auth.credentials

        user = User.authenticate(username, password)

        unless user
          error(403, {error: 'Authentication failed!'}.to_json)
        end

        oauth = Songkick::OAuth2::Model::Authorization.new
        oauth.owner = user
        oauth.client = OauthApp.api_client
        oauth.save!
        token = oauth.generate_access_token

        status 201
        {token: token}.to_json
      end

      post '/token/app' do
        ensure_authentication!
        app_id, app_secret = auth.credentials

        app = OauthApp.where(client_id: app_id).first
        unless app && app.valid_client_secret?(app_secret)
          error(403, {error: 'Authentication failed!'}.to_json)
        end

        oauth = Songkick::OAuth2::Model::Authorization.new
        oauth.owner = app
        oauth.client = app
        oauth.save!
        token = oauth.generate_access_token

        status 201
        {token: token}.to_json
      end
    end
  end
end

