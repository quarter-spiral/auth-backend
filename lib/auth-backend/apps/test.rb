require 'json'

module Auth::Backend
  module Apps
    class Test < Sinatra::Base
      register Base

      post '/users' do
        user = Auth::Backend::User.new(params)
        params.each do |key, value|
          user.send("#{key}=", value)
        end
        user.save!
        user.to_json
      end

      delete '/users/:id' do
        Auth::Backend::User.find(params[:id]).destroy
        'done'
      end

      get '/users' do
        Auth::Backend::User.all.to_json
      end
    end
  end
end