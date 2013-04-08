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

        def prevent_access!
          error(403, {error: "Not authorized!"}.to_json)
        end

        def own_data?(uuid)
          token_owner.private_info['uuid'] == uuid
        end

        def system_level_privileges?
          token_owner.private_info['type'] == 'app'
        end

        def is_authorized_to_access?(uuid)
          system_level_privileges? || own_data?(uuid)
        end

        def owner_only!(uuid = params[:uuid])
          ensure_authentication!
          prevent_access! unless is_authorized_to_access?(uuid)
        end

        def system_privileges_only!
          ensure_authentication!
          prevent_access! unless system_level_privileges?
        end

        def issue_token_for_user(user)
          oauth = Songkick::OAuth2::Model::Authorization.send(:new)
          oauth.owner = user
          oauth.client = OauthApp.api_client
          oauth.access_token = Songkick::OAuth2::Model::Authorization.create_access_token
          oauth.save!
          oauth.access_token
        end

        def issue_token_for_app(app)
          oauth = Songkick::OAuth2::Model::Authorization.send(:new)
          oauth.owner = app
          oauth.client = app
          oauth.access_token = Songkick::OAuth2::Model::Authorization.create_access_token
          oauth.save!
          oauth.access_token
        end

        def respond_with_token(token)
          status 201
          {token: token}.to_json
        end

        def request_token
          @request_token ||= Songkick::OAuth2::Provider.access_token(nil, [], env)
        end

        def token_owner
          @token_owner ||= request_token.owner
        end

        def create_venue_identity(venue, params)
          venue_id = params['venue-id']
          name = params['name']
          email = params['email'].blank? ? 'unknown@example.com' : params['email']

          error(422, {error: 'Please provide venue-id and name'}) if venue_id.blank? || name.blank?

          token = own_token
          user = User.new(name: name, email: email)
          venue_identity = nil
          User.transaction do
            user.save!(validate: false)
            venue_identity = VenueIdentity.create!(user_id: user.id, venue: venue, venue_id: venue_id, email: email, name: name)
          end

          # This can't be in the transaction as it reaches out to the graph which checks the just created token
          # therefore the transaction has to be committed
          begin
            connection.graph.add_role(user.uuid, token, 'player')
          rescue Exception => e
            user.destroy
            raise e
          end

          venue_identity
        rescue ActiveRecord::RecordInvalid => e
          error(422, {error: 'Could not create a token on the given venue with the given venue data'}.to_json)
        end

        def find_venue_identity(venue, params)
          venue_id = params['venue-id']
          error(422, {error: 'Please provide venue-id'}) if venue_id.blank?

          VenueIdentity.where(venue: venue, venue_id: venue_id).first
        end

        def find_or_create_venue_identity(venue, params)
          venue_identity = find_venue_identity(venue, params) ||
                           create_venue_identity(venue, params)
        end

        def user_info(user)
          {uuid: user.uuid, venues: user.venues}.to_json
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
        prevent_access! unless request_token.valid?

        body = request.body
        body = body.read if body.respond_to?(:read)

        uuids = JSON.parse(body)

        prevent_access! if !system_level_privileges? && (uuids.size > 1 || uuids[0] != request_token.owner.uuid)

        users = User.where(uuid: uuids).includes(:venue_identities).all
        error(404, {error: "A user does not exist!"}) unless users.size == uuids.size

        Hash[users.map {|u| [u.uuid, {uuid: u.uuid, venues: u.venues}]}].to_json
      end

      get "/users/:uuid/identities" do
        owner_only!(params[:uuid])

        user = User.where(uuid: params[:uuid]).first
        error(404, {error: "User does not exist!"}.to_json) unless user

        user_info(user)
      end

      post "/users/:uuid/identities" do
        owner_only!(params[:uuid])

        body = request.body
        body = body.read if body.respond_to?(:read)
        data = JSON.parse(body)

        user = User.where(uuid: params[:uuid]).first
        error(404, {error: "User does not exist!"}.to_json) unless user

        VenueIdentity.transaction do
          data.each do |venue, venue_information|
            existing_identity = find_venue_identity(venue, venue_information)

            if !existing_identity && !user.venue_identities.where(venue: venue).first
              VenueIdentity.create!(user_id: user.id, venue: venue, venue_id: venue_information['venue-id'], email: venue_information['email'] || 'unknown@example.com', name: venue_information['name'])
            end
          end
        end

        status 201
        user_info(user)
      end

      post "/uuids/batch" do
        system_privileges_only!

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
        prevent_access! unless request_token.valid?

        request_token.owner.private_info.to_json
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

