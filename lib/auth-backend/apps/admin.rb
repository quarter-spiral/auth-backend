module Auth::Backend
  module Apps
    class Admin < Sinatra::Base
      register Base

      before do
        env['NAMESPACE_INFO'] = '/admin'

        authorize!('/login')
        redirect('/login') unless current_user.admin?
      end


      get '/' do
        erb :'admin/index'
      end

      get '/users' do
        @users = User.page(params[:page])

        erb :'admin/users/index'
      end

      get '/users/:id/edit' do
        @user = User.find(params[:id])

        erb :'admin/users/edit'
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

      get '/apps' do
        @apps = Songkick::OAuth2::Model::Client.page(params[:page])

        erb :'admin/apps/index'
      end

      get '/apps/new' do
        @app = Songkick::OAuth2::Model::Client.new

        erb :'admin/apps/new'
      end

      post '/apps' do
        @app = Songkick::OAuth2::Model::Client.new(params[:app])

        if @app.save
          flash[:success] = "App created. App secret is: #{@app.client_secret} This information will not be stored!"
          redirect '/admin/apps'
        else
          flash.now[:error] = "Could not create app!"
          erb :'admin/apps/new'
        end
      end

      get '/apps/:id/edit' do
        @app = Songkick::OAuth2::Model::Client.find(params[:id])

        erb :'admin/apps/edit'
      end

      put '/apps/:id' do
        @app = Songkick::OAuth2::Model::Client.find(params[:id])

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
        @app = Songkick::OAuth2::Model::Client.find(params[:id])
        @app.destroy

        flash[:success] = "App deleted."

        redirect '/admin/apps'
      end
    end
  end
end