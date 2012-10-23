require_relative '../spec_helper.rb'

require 'json'
require 'uri'

def must_redirect_to(path, response)
  response.status.must_equal 302
  URI.parse(response.headers['Location']).path.must_equal path
end

describe "Authentication API" do
  before do
    User.destroy_all
    @password = 'schackalacka'
    @user = TEST_HELPERS.create_user!(password: @password, admin: 'false')

    Apps.setup_oauth_api_client_app!
  end

  describe "OAuth API" do
    it "can't get a token without credentials" do
      response = client.post("http://auth-backend.dev/api/v1/token")
      response.status.must_equal 403
    end

    it "can't get a token with wrong credentials" do
      username = @user['name']
      password = @password.reverse

      authed_client = Rack::Client.new {
        run Rack::Client::Auth::Basic.new(APP, username, password, true)
      }

      response = authed_client.post("http://auth-backend.dev/api/v1/token")
      response.status.must_equal 403
    end

    describe "correctly authenticated" do
      before do
        username = @user['name']
        password = @password

        authed_client = Rack::Client.new {
          run Rack::Client::Auth::Basic.new(APP, username, password, true)
        }
        @response = authed_client.post("http://auth-backend.dev/api/v1/token")
        @token = JSON.parse(@response.body)['token']
      end
      it "can get a token with valid credentials" do
        @response.status.must_equal 201
        @token.wont_be_nil
      end

      it "returns information about the token owner" do
        response = client.get("http://auth-backend.dev/api/v1/me", 'Authorization' => "Bearer #{@token}")
        response.status.must_equal 200
        user = JSON.parse(response.body)
        user['name'].must_equal @user['name']
        user['email'].must_equal @user['email']
        user['uuid'].must_equal @user['uuid']
        user['type'].must_equal 'user'
      end

      it "can verify a token" do
        response = client.get("http://auth-backend.dev/api/v1/verify", 'Authorization' => "Bearer #{@token.reverse}")
        response.status.wont_equal 200

        response = client.get("http://auth-backend.dev/api/v1/verify", 'Authorization' => "Bearer #{@token}")
        response.status.must_equal 200
      end
    end

    describe "with an authed app" do
      before do
        app = TEST_HELPERS.create_app!

        authed_client = Rack::Client.new {
          run Rack::Client::Auth::Basic.new(APP, app[:id], app[:secret], true)
        }
        response = authed_client.post('http://auth-backend.dev/api/v1/token/app')
        @app_token = JSON.parse(response.body)['token']
        @app_token.wont_be_empty
      end

      it "can get a token on behalf of an app" do

        response = client.get("http://auth-backend.dev/api/v1/me", 'Authorization' => "Bearer #{@app_token}")
        info = JSON.parse(response.body)
        info['type'].must_equal 'app'

        response = client.get("http://auth-backend.dev/api/v1/verify", 'Authorization' => "Bearer #{@app_token}")
        response.status.must_equal 200
      end

      describe "venue tokens" do
        before do
          VenueIdentity.destroy_all

          @venue_data = {
            "venue-id" => "1234567",
            "name" => "Peter Smith",
            "email" => "peter@example.com"
          }
        end

        it "can be created by apps" do
          response = client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@venue_data))
          response.status.must_equal 201
          token = JSON.parse(response.body)['token']
        end

        it "can't be created by apps" do
          response = client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer 1337"}, JSON.dump(@venue_data))
          response.status.must_equal 403
        end

        it "can't be created by users" do
          username = @user['name']
          password = @password

          authed_client = Rack::Client.new {
            run Rack::Client::Auth::Basic.new(APP, username, password, true)
          }
          response = authed_client.post("http://auth-backend.dev/api/v1/token")
          token = JSON.parse(response.body)['token']

          client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{token}"}, JSON.dump(@venue_data)).status.must_equal 403
        end

        describe "with a created venue user" do
          before do
            @token = JSON.parse(client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@venue_data)).body)['token']
          end

          it "is issued for the correct user" do
            info = JSON.parse(client.get("http://auth-backend.dev/api/v1/me", {'Authorization' => "Bearer #{@token}"}).body)

            info['name'].must_equal @venue_data['name']
            info['email'].must_equal @venue_data['email']
            info['type'].must_equal 'user'
          end

          it "will only create a user once" do
            response = client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@venue_data))
            new_token = JSON.parse(response.body)['token']

            uuid1 = JSON.parse(client.get("http://auth-backend.dev/api/v1/me", {'Authorization' => "Bearer #{@token}"}).body)['uuid']
            uuid2 = JSON.parse(client.get("http://auth-backend.dev/api/v1/me", {'Authorization' => "Bearer #{new_token}"}).body)['uuid']

            uuid1.must_equal uuid2
          end

          #TODO: check if only apps can do it
        end
      end
    end
  end
end
