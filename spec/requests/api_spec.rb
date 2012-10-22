require_relative '../spec_helper.rb'

require 'rack/client'
require 'json'
require 'uri'

include Auth::Backend

APP = App.new(test: true)
CLIENT = Rack::Client.new {run APP}
def client
  @client ||= CLIENT
end

TEST_MOUNT = '/_tests_'

require 'auth-backend/test_helpers'
test_helpers = TestHelpers.new(APP)

def must_redirect_to(path, response)
  response.status.must_equal 302
  URI.parse(response.headers['Location']).path.must_equal path
end

describe "Authentication API" do
  before do
    User.destroy_all
    @password = 'schackalacka'
    @user = test_helpers.create_user!(password: @password, admin: 'false')

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

    it "can get a token on behalf of an app" do
      app = test_helpers.create_app!

      authed_client = Rack::Client.new {
        run Rack::Client::Auth::Basic.new(APP, app[:id], app[:secret], true)
      }
      response = authed_client.post('http://auth-backend.dev/api/v1/token/app')
      token = JSON.parse(response.body)['token']
      token.wont_be_empty

      response = client.get("http://auth-backend.dev/api/v1/me", 'Authorization' => "Bearer #{token}")
      info = JSON.parse(response.body)
      info['type'].must_equal 'app'

      response = client.get("http://auth-backend.dev/api/v1/verify", 'Authorization' => "Bearer #{token}")
      response.status.must_equal 200
    end
  end
end
