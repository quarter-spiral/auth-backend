require 'uri'
require 'omniauth'
require 'omniauth-facebook'
require 'futuroscope'

module Auth::Backend
  module Apps
    class Authentication < Sinatra::Base
      register Base

      set :auth_template_renderer, :erb
      set :auth_login_template, :'authentication/login'
      enable :auth_use_referrer

      set :protection, :except => [:frame_options, :xss_header]

      use OmniAuth::Builder do
        provider :facebook, ENV['QS_FB_APP_ID'], ENV['QS_FB_APP_SECRET'], :scope => 'email'
      end

      helpers do
        def issue_token_for_user(user)
          oauth = Songkick::OAuth2::Model::Authorization.send(:new)
          oauth.owner = user
          oauth.client = ::Auth::Backend::OauthApp.api_client
          oauth.access_token = Songkick::OAuth2::Model::Authorization.create_access_token
          oauth.save!
          oauth.access_token
        end
      end

      before do
        break if request.path_info == "/accept-tos" || request.path_info.start_with?('/assets/') || request.url.match(/favicon\.ico$/)

        if current_user && !current_user.accepted_current_tos?
          session[:after_tos_acceptance_url] ||= request.url
          redirect '/accept-tos'
        end
      end

      get '/signup' do
        # Do not allow signups in production!
        # redirect '/' and return if settings.production?

        redirect '/' and return if current_user

        @user = User.new
        erb :'authentication/signup'
      end

      post '/signup' do
        # Do not allow signups in production!
        # redirect '/' and return if settings.production?

        redirect '/' and return if current_user

        @user = User.new(params[:user])

        if @user.save and VenueIdentity.new(:user_id => @user.id, :venue_id => @user.uuid, :name => @user.name, :email => @user.email, :venue => 'embedded').save
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
          redirect ::URI.decode(params[:redirect_uri])
        else
          redirect settings.auth_success_path
        end
      end

      get '/auth/denied' do
        erb :'authentication/denied'
      end

      get '/auth/facebook/callback' do
        fb_data = {}
        fb_data[:name] = request.env['omniauth.auth']['info']['name']
        fb_data[:id] = request.env['omniauth.auth']['uid']
        fb_data[:email] = request.env['omniauth.auth']['info']['email']

        venue_id = VenueIdentity.where(venue: 'facebook', venue_id: fb_data[:id]).includes(:user).first

        unless venue_id
          user = User.new(name: fb_data[:name], email: fb_data[:email])
          User.transaction do
            user.save!(validate: false)
            venue_id = VenueIdentity.create!(user_id: user.id, venue: 'facebook', venue_id: fb_data[:id], email: user.email, name: user.name)
          end
        end

        fb_token = request.env['omniauth.auth']['credentials']['token'].clone
        fb_uuid = fb_data[:id].clone
        qs_token = issue_token_for_user(venue_id.user)
        qs_uuid = venue_id.user.uuid.clone

        Futuroscope::Future.new do
          begin
            facebook_client = ::Facebook::Client.new(ENV['QS_FB_APP_ID'], ENV['QS_FB_APP_SECRET'])
            authenticated_client = facebook_client.authenticated_by(fb_token)
            friends = authenticated_client.friends_of(fb_uuid)
            friends.map! {|f| {"venue-id" => f.identifier, "name" => f.name, "email" => f.email}}
            ::Auth::Backend::Connection.create.playercenter.update_friends_of(qs_uuid, qs_token, 'facebook', friends)
          rescue Exception => e
            $STDERR.puts "Error in FB friend update: #{e.message} / #{e.inspect}"
          end
        end

        self.user = venue_id.user
        redirect session[:return_to] || '/'
      end

      get '/' do
        redirect '/invite' and return if session[:uninvited_user]

        authorize!('/login')
        redirect '/admin' and return if current_user.admin?

        erb :'authentication/index'
      end

      get '/invite' do
        if authenticated?
          redirect '/' and return if current_user.invited?
        else
          redirect '/login'
          return
        end

        erb :'authentication/invite'
      end

      post '/invite' do
        redirect '/login' and return unless authenticated?

        invitation = UserInvitation.redeemable.where(code: params[:code]).first
        unless invitation
          flash[:error] = "Invitation code invalid"
          redirect '/invite'
          return
        end

        if invitation.redeem_for(current_user)
          redirect session[:return_to] || '/'
        else
          flash[:error] = "Could not redeem the invitation code"
          redirect '/invite'
        end
      end

      get '/accept-tos' do
        erb :'authentication/accept_tos'
      end

      post '/accept-tos' do
        current_user.accept_current_tos!(params['accept-tos'])
        current_user.save!(validate: false)

        after_tos_acceptance_url = session.delete(:after_tos_acceptance_url)
        redirect after_tos_acceptance_url || '/'
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
          flash.now[:error] = "Could not save your profile."

          erb :'authentication/profile'
        end
      end

      {'/oauth/authorize' => :get, '/oauth/token' => :post}.each do |route, method|
        __send__(method, route) do

          @owner  = current_user
          @oauth2 = Songkick::OAuth2::Provider.parse(@owner, env)

          if @oauth2.redirect?
            if @oauth2.client.needs_invitation && @owner && !@owner.invited?
              redirect '/invite'
            else
              redirect @oauth2.redirect_uri, @oauth2.response_status
            end
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
              if @oauth2.client.automatic_authorization
                @oauth2.grant_access!
                redirect @oauth2.redirect_uri
              else
                erb :'authentication/grant_access'
              end
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
          session[:return_to] = @auth.redirect_uri
          redirect '/invite' and return if @auth.client.needs_invitation && !current_user.invited?
        else
          @auth.deny_access!
        end
        redirect @auth.redirect_uri, @auth.response_status
      end
    end
  end
end
