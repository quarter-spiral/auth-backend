require 'uri'

module Auth::Backend
  module Apps
    class API < Sinatra::Base
      register Base

      helpers do
        def connection
          @connection ||= Connection.create(ENV['QS_GRAPH_BACKEND_URL'])
        end

        def own_token
          return @own_token if @own_token

          app = OauthApp.where(name: 'Auth Backend').first
          unless app
            app = OauthApp.create!(name: 'Auth Backend', redirect_uri: 'http://auth-backend.example.com/')
          end

          @own_token = issue_token_for_app(app)
        end

        def auth
          @auth ||= Rack::Auth::Basic::Request.new(env)
        end

        def ensure_authentication!
          unless auth.provided?
            error(403, {error: 'Authentication missing!'}.to_json)
          end
        end

        def issue_token_for_user(user)
          oauth = Songkick::OAuth2::Model::Authorization.new
          oauth.owner = user
          oauth.client = OauthApp.api_client
          oauth.save!
          oauth.generate_access_token
        end

        def issue_token_for_app(app)
          oauth = Songkick::OAuth2::Model::Authorization.new
          oauth.owner = app
          oauth.client = app
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

        def create_venue_identity(venue, venue_id, name, email)
          User.transaction do
            user = User.new(name: name, email: email)
            user.save!(validate: false)
            venue_identity = VenueIdentity.create!(user_id: user.id, venue: venue, venue_id: venue_id, email: email, name: name)
            connection.graph.add_role(user.uuid, own_token, 'player')
            venue_identity
          end
        rescue ActiveRecord::RecordInvalid => e
          error(422, {error: 'Could not create a token on the given venue with the given venue data'}.to_json)
        end

        def find_or_create_venue_identity(venue, params)
          venue_id = params['venue-id']
          name = params['name']
          email = params['email'].blank? ? 'unknown@example.com' : params['email']

          error(422, {error: 'Please provide name and venue-id'}) if venue_id.blank? || name.blank?

          venue_identity = VenueIdentity.where(venue: venue, venue_id: venue_id).first

          venue_identity ||= create_venue_identity(venue, venue_id, name, email)
        end
      end

      before do
        content_type :json
        headers 'Access-Control-Allow-Origin' => request.env['HTTP_ORIGIN'] || '*'
      end

      options '/*' do
        headers(
          'Access-Control-Allow-Headers' => 'origin, x-requested-with, content-type, accept, authorization',
          'Access-Control-Allow-Methods' => 'GET,POST'
        )
        ''
      end

      get "/users/batch/identities" do
        ensure_authentication!
        unless request_token.valid?
          error(403, {error: "Not authorized!"}.to_json)
        end

        body = request.body
        body = body.read if body.respond_to?(:read)

        users = JSON.parse(body).map {|uuid| User.where(uuid: uuid).first}
        error(404, {error: "A user does not exist!"}) unless users.select {|u| u.nil?}.empty?

        Hash[users.map {|u| [u.uuid, {uuid: u.uuid, venues: u.venues}]}].to_json
      end

      get "/users/:uuid/identities" do
        ensure_authentication!
        unless request_token.valid?
          error(403, {error: "Not authorized!"}.to_json)
        end

        user = User.where(uuid: params[:uuid]).first
        error(404, {error: "User does not exist!"}.to_json) unless user

        {uuid: user.uuid, venues: user.venues}.to_json
      end

      post "/uuids/batch" do
        body = request.body
        body = body.read if body.respond_to?(:read)
        venue_information = JSON.parse(body)

        result = {}
        venue_information.each do |venue, identities|
          venue_result = {}
          identities.each do |identity|
            venue_identity = find_or_create_venue_identity(venue, identity)
            venue_result[venue_identity.venue_id] = venue_identity.user.uuid
          end
          result[venue] = venue_result
        end

        result.to_json
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

        token = issue_token_for_app(app)

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

        body = request.body
        body = body.read if body.respond_to?(:read)
        actual_params = JSON.parse(body).merge(params)

        venue_identity = find_or_create_venue_identity(actual_params['venue'], actual_params)

        token = issue_token_for_user(venue_identity.user)
        respond_with_token(token)
      end
    end
  end
end

