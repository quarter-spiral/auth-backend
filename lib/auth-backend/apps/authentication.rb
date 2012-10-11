require 'uri'

module Auth::Backend
  module Apps
    class Authentication < Sinatra::Base
      register Base

      set :auth_template_renderer, :erb
      set :auth_login_template, :'authentication/login'
      enable :auth_use_referrer

      get '/signup' do
        redirect '/' and return if current_user

        @user = User.new
        erb :'authentication/signup'
      end

      post '/signup' do
        redirect '/' and return if current_user

        @user = User.new(params[:user])

        if @user.save
          flash[:success] = "Signed up!"

          redirect '/'
        else
          flash.now[:error] = "Could not sign you up!"

          erb :'authentication/signup'
        end
      end

      get '/signout' do
        authorize!
        logout
        env['x-rack.flash'][:success] = settings.auth_success_message if defined?(Rack::Flash)
        if params[:redirect_uri]
          redirect URI.decode(params[:redirect_uri])
        else
          redirect settings.auth_success_path
        end
      end

      get '/' do
        authorize!('/login')
        redirect '/admin' and return if current_user.admin?

        erb :'authentication/index'
      end

      get '/profile' do
        authorize!('/login')

        @user = current_user
        erb :'authentication/profile'
      end

      put '/profile' do
        authorize!('/login')

        @user = current_user
        @user.update_attributes(params[:user])

        if @user.save
          flash[:success] = 'Profile updated.'
          redirect '/profile'
        else
          flash.now[:error] = "Could not save your profile"
          erb :'authentication/profile'
        end
      end

      {'/oauth/authorize' => :get, '/oauth/token' => :post}.each do |route, method|
        __send__(method, route) do

          @owner  = current_user
          @oauth2 = Songkick::OAuth2::Provider.parse(@owner, env)

          if @oauth2.redirect?
            redirect @oauth2.redirect_uri, @oauth2.response_status
          end

          headers @oauth2.response_headers
          status  @oauth2.response_status

          if body = @oauth2.response_body
            body
          elsif @oauth2.valid?
            unless @owner
              session[:return_to] = "#{request.path}?#{request.query_string}"
              redirect '/login'
            else
              erb :'authentication/grant_access'
            end
          else
            erb 'An error occured'
          end
        end
      end

      post '/oauth/allow' do
        authorize!('/login')
        @auth = Songkick::OAuth2::Provider::Authorization.new(current_user, params)

        if params['allow'] == '1'
          @auth.grant_access!
        else
          @auth.deny_access!
        end
        redirect @auth.redirect_uri, @auth.response_status
      end

      get '/api/v1/me' do
        content_type :json
        token = Songkick::OAuth2::Provider.access_token(nil, [], env)

        if token.valid?
          token.owner.private_info.to_json
        else
          status 403
          {error: 'Not authorized!'}.to_json
        end
      end

      get '/api/v1/verify' do
        token = Songkick::OAuth2::Provider.access_token(nil, [], env)
        status token.valid? ? 200 : 403
        ''
      end

      post '/api/v1/token' do
        content_type :json

        auth = Rack::Auth::Basic::Request.new(env)
        unless auth.provided?
          error(403, {error: 'Authenticate with HTTP basic auth!'}.to_json)
        end
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

      post '/api/v1/token/app' do
        content_type :json

        auth = Rack::Auth::Basic::Request.new(env)
        unless auth.provided?
          error(403, {error: 'Authenticate with HTTP basic auth!'}.to_json)
        end
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
