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

  describe "User API" do
    before do
      username = @user['name']
      password = @password

      authed_client = Rack::Client.new {
       run Rack::Client::Auth::Basic.new(APP, username, password, true)
      }
      response = authed_client.post("http://auth-backend.dev/api/v1/token")
      @token = JSON.parse(response.body)['token']

      VenueIdentity.destroy_all
      @facebook_data = {
        "venue-id" => "1234567",
        "name" => "Peter Smith",
        "email" => "peter@example.com"
      }
      @galaxy_spiral_data = {
        "venue-id" => "asff3564",
        "name" => "Peter S",
        "email" => "psmith@example.com"
      }

      app = TEST_HELPERS.create_app!

      authed_client = Rack::Client.new {
        run Rack::Client::Auth::Basic.new(APP, app[:id], app[:secret], true)
      }
      response = authed_client.post('http://auth-backend.dev/api/v1/token/app')
      @app_token = JSON.parse(response.body)['token']
    end

    it "can get the venue identities of a user" do
      response = client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@facebook_data))
      response.status.must_equal 201
      response = client.post("http://auth-backend.dev/api/v1/token/venue/galaxy-spiral", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@galaxy_spiral_data))
      response.status.must_equal 201
      VenueIdentity.count.must_equal 2
      VenueIdentity.all.each {|vi| vi.user = User.find(@user['id']); vi.save!}

      uuid = @user['uuid']

      response = client.get "http://auth-backend.dev/api/v1/users/#{uuid}/identities", {'Authorization' => "Bearer #{@token}"}
      response.status.must_equal 200

      data = JSON.parse(response.body)
      data['uuid'].must_equal uuid
      data['venues'].must_equal(
        'facebook' => {'name' => @facebook_data['name'],
                       'id' => @facebook_data['venue-id']},
        'galaxy-spiral' => {'name' => @galaxy_spiral_data['name'],
                            'id' => @galaxy_spiral_data['venue-id']}
      )
    end

    it "can get the venue identities of a bunch of users" do
      response = client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@facebook_data))
      response.status.must_equal 201
      response = client.post("http://auth-backend.dev/api/v1/token/venue/galaxy-spiral", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@galaxy_spiral_data))
      response.status.must_equal 201
      VenueIdentity.count.must_equal 2
      VenueIdentity.all.each {|vi| vi.user = User.find(@user['id']); vi.save!}

      @user2 = TEST_HELPERS.create_user!(name: 'Sam', email: 'sam@example.com', password: @password, admin: 'false')
      response = client.post("http://auth-backend.dev/api/v1/token/venue/galaxy-spiral", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump({
        'venue-id' => '438957380',
        'name' => 'Sam The Man',
        'email' => 'samman@example.com'
      }))
      response.status.must_equal 201
      vi = VenueIdentity.where('venue_id' => '438957380').first
      vi.user_id = @user2['id']
      vi.save!

      @user3 = TEST_HELPERS.create_user!(name: 'Jacko', email: 'jacko@example.com', password: @password, admin: 'false')

      response = client.get "http://auth-backend.dev/api/v1/users/batch/identities", {'Authorization' => "Bearer #{@token}"}, JSON.dump([@user['uuid'], @user2['uuid'], @user3['uuid']])
      response.status.must_equal 200

      data = JSON.parse(response.body)
      data.must_equal({
        @user['uuid'] => {
          'uuid' => @user['uuid'],
          'venues' => {
            'facebook' => {'name' => @facebook_data['name'],
                           'id' => @facebook_data['venue-id']},
             'galaxy-spiral' => {'name' => @galaxy_spiral_data['name'],
                                 'id' => @galaxy_spiral_data['venue-id']}
          }
        },
        @user2['uuid'] => {
          'uuid' => @user2['uuid'],
          'venues' => {
            'galaxy-spiral' => {'name' => 'Sam The Man', 'id' => '438957380'}
          }
        },
        @user3['uuid'] => {
          'uuid' => @user3['uuid'],
          'venues' => {}
        }
      })
    end
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

        it "can't be created by bullshit tokens" do
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

        it "can't be created for bullshit venues" do
          response = client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@venue_data))
          response.status.must_equal 201

          response = client.post("http://auth-backend.dev/api/v1/token/venue/galaxy-spiral", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@venue_data))
          response.status.must_equal 201

          response = client.post("http://auth-backend.dev/api/v1/token/venue/bullshit", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@venue_data))
          response.status.wont_equal 201
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
        end
      end
    end
  end
end
