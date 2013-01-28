module Auth::Backend
  module Apps
    class Admin < Sinatra::Base
      register Base

      before do
        env['NAMESPACE_INFO'] = '/admin'

        authorize!('/login')
        redirect('/login') unless has_admin_privileges?

        @controller_id = 'admin'
      end

      get '/' do
        erb :'admin/index'
      end

      get '/users' do
        @users = User.page(params[:page])

        erb :'admin/users/index'
      end

      get '/users/search' do
        @query = params[:q]
        query = "%#{@query}%"
        @users = User.where(['users.name LIKE ? OR users.email LIKE ? OR users.uuid LIKE ?', query, query, query]).page(params[:page])

        erb :'admin/users/index'
      end

      get '/users/:id/edit' do
        @user = User.find(params[:id])

        erb :'admin/users/edit'
      end

      post '/users/:id/impersonate' do
        user = User.find(params[:id])
        warden_data[:user] = user.id
        if user.id == current_user.id
          flash[:success] = "Impersonating stopped"
        else
          flash[:success] = "Now impersonating #{user.name} (#{user.id})"
        end

        redirect '/admin'
      end

      get '/users/new' do
        @user = User.new
        erb :'admin/users/new'
      end

      put '/users/:id' do
        @user = User.find(params[:id])

        admin = params[:user].delete('admin')

        @user.update_attributes(params[:user])

        @user.admin = admin if admin && admin == 'true'
        if @user.save
          flash[:success] = "User saved."
          redirect '/admin/users'
        else
          flash.now[:error] = "Could not save user!"
          erb :'admin/users/edit'
        end
      end

      delete '/users/:id' do
        @user = User.find(params[:id])
        @user.destroy

        flash[:success] = "User deleted."

        redirect '/admin/users'
      end

      post "/users" do
        admin = params[:user].delete('admin')

        @user = User.new(params[:user])
        @user.admin = admin if admin && admin == 'true'
        if @user.save
          flash[:success] = "User created."
          redirect '/admin/users'
        else
          flash.now[:error] = "Could not create user!"
          erb :'admin/users/new'
        end
      end

      get '/user_invitations' do
        @user_invitations = UserInvitation.includes(:user).order('user_invitations.redeemed_at ASC, user_invitations.created_at DESC').page(params[:page])

        erb :'admin/user_invitations/index'
      end

      post '/user_invitations' do
        user_invitation = UserInvitation.create!
        flash[:success] = "Invitation code #{user_invitation.code} generated."

        redirect '/admin/user_invitations'
      end

      delete '/user_invitations/:id' do
        user_invitation = UserInvitation.find(params[:id])
        user_invitation.destroy

        flash[:success] = "Invitation #{user_invitation.code} deleted."

        redirect '/admin/user_invitations'
      end

      get '/apps' do
        @apps = OauthApp.page(params[:page])

        erb :'admin/apps/index'
      end

      get '/apps/new' do
        @app = OauthApp.new

        erb :'admin/apps/new'
      end

      post '/apps' do
        @app = OauthApp.new(params[:app])

        if @app.save
          flash[:success] = "App created. App secret is: #{@app.client_secret} This information will not be stored!"
          redirect '/admin/apps'
        else
          flash.now[:error] = "Could not create app!"
          erb :'admin/apps/new'
        end
      end

      get '/apps/:id/edit' do
        @app = OauthApp.find(params[:id])

        erb :'admin/apps/edit'
      end

      put '/apps/:id' do
        @app = OauthApp.find(params[:id])

        @app.update_attributes(params[:app])

        if @app.save
          flash[:success] = "App saved."
          redirect '/admin/apps'
        else
          flash.now[:error] = "Could not save app!"
          erb :'admin/apps/edit'
        end
      end

      delete '/apps/:id' do
        @app = OauthApp.find(params[:id])
        @app.destroy

        flash[:success] = "App deleted."

        redirect '/admin/apps'
      end
    end
  end
end
