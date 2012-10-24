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

        def issue_token_for_user(user)
          oauth = Songkick::OAuth2::Model::Authorization.new
          oauth.owner = user
          oauth.client = OauthApp.api_client
          oauth.save!
          oauth.generate_access_token
        end

        def respond_with_token(token)
          status 201
          {token: token}.to_json
        end

        def request_token
          @request_token ||= Songkick::OAuth2::Provider.access_token(nil, [], env)
        end
      end

      before do
        content_type :json
      end

      get '/me' do
        if request_token.valid?
          request_token.owner.private_info.to_json
        else
          status 403
          {error: 'Not authorized!'}.to_json
        end
      end

      get '/verify' do
        status request_token.valid? ? 200 : 403
        ''
      end

      post '/token' do
        ensure_authentication!
        username, password = auth.credentials

        user = User.authenticate(username, password)

        unless user
          error(403, {error: 'Authentication failed!'}.to_json)
        end

        token = issue_token_for_user(user)
        respond_with_token(token)
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

        respond_with_token(token)
      end

      post '/token/venue/:venue' do
        ensure_authentication!

        unless request_token.valid?
          error(403, {error: "Not authorized!"}.to_json)
        end

        unless request_token.owner.private_info['type'] == 'app'
          error(403, {error: "Forbidden as a user"}.to_json)
        end

        actual_params = JSON.parse(request.body.string).merge(params)

        venue = actual_params['venue']
        venue_id = actual_params['venue-id']
        name = actual_params['name']
        email = actual_params['email']

        error(422, {error: 'Please provide name and venue-id'}) if venue_id.blank? || name.blank?

        venue_identity = VenueIdentity.where(venue: venue, venue_id: venue_id).first

        unless venue_identity
          User.transaction do
            user = User.new(name: name, email: email)
            user.save!(validate: false)
            venue_identity = VenueIdentity.create!(user_id: user.id, venue: venue, venue_id: venue_id)
          end
        end

        token = issue_token_for_user(venue_identity.user)
        respond_with_token(token)
      end
    end
  end
end

