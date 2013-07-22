require_relative '../request_spec_helper.rb'

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
      @spiral_galaxy_data = {
        "venue-id" => "asff3564",
        "name" => "Peter S",
        "email" => "psmith@example.com"
      }

      @app_token = get_app_token
    end

    it "can get the venue identities of a user" do
      response = client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@facebook_data))
      response.status.must_equal 201
      response = client.post("http://auth-backend.dev/api/v1/token/venue/spiral-galaxy", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@spiral_galaxy_data))
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
        'spiral-galaxy' => {'name' => @spiral_galaxy_data['name'],
                            'id' => @spiral_galaxy_data['venue-id']}
      )
    end

    it "returns 404 when retrieving the venue identities of a non existing user" do
      non_existing_uuid = '999999999999'
      response = client.get "http://auth-backend.dev/api/v1/users/#{non_existing_uuid}/identities", {'Authorization' => "Bearer #{@app_token}"}
      response.status.must_equal 404
    end

    it "can get the venue identities of a bunch of users" do
      response = client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@facebook_data))
      response.status.must_equal 201
      response = client.post("http://auth-backend.dev/api/v1/token/venue/spiral-galaxy", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@spiral_galaxy_data))
      response.status.must_equal 201
      VenueIdentity.count.must_equal 2
      VenueIdentity.all.each {|vi| vi.user = User.find(@user['id']); vi.save!}

      @user2 = TEST_HELPERS.create_user!(name: 'Sam', email: 'sam@example.com', password: @password, admin: 'false')
      response = client.post("http://auth-backend.dev/api/v1/token/venue/spiral-galaxy", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump({
        'venue-id' => '438957380',
        'name' => 'Sam The Man',
        'email' => 'samman@example.com'
      }))
      response.status.must_equal 201
      vi = VenueIdentity.where('venue_id' => '438957380').first
      vi.user_id = @user2['id']
      vi.save!

      @user3 = TEST_HELPERS.create_user!(name: 'Jacko', email: 'jacko@example.com', password: @password, admin: 'false')

      response = client.get "http://auth-backend.dev/api/v1/users/batch/identities", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump([@user['uuid'], @user2['uuid'], @user3['uuid']])
      response.status.must_equal 200

      data = JSON.parse(response.body)
      data.must_equal({
        @user['uuid'] => {
          'uuid' => @user['uuid'],
          'venues' => {
            'facebook' => {'name' => @facebook_data['name'],
                           'id' => @facebook_data['venue-id']},
             'spiral-galaxy' => {'name' => @spiral_galaxy_data['name'],
                                 'id' => @spiral_galaxy_data['venue-id']}
          }
        },
        @user2['uuid'] => {
          'uuid' => @user2['uuid'],
          'venues' => {
            'spiral-galaxy' => {'name' => 'Sam The Man', 'id' => '438957380'}
          }
        },
        @user3['uuid'] => {
          'uuid' => @user3['uuid'],
          'venues' => {}
        }
      })
    end

    it "can attach a venue identity to a user" do
      uuid = @user['uuid']
      response = client.get("http://auth-backend.dev/api/v1/users/#{uuid}/identities", {"Authorization" => "Bearer #{@token}"})
      identities = JSON.parse(response.body)
      identities['venues'].empty?.must_equal true

      client.post("http://auth-backend.dev/api/v1/users/#{uuid}/identities", {"Authorization" => "Bearer #{@token}"}, JSON.dump('facebook' => @facebook_data))
      response = client.post("http://auth-backend.dev/api/v1/users/#{uuid}/identities", {"Authorization" => "Bearer #{@token}"}, JSON.dump('spiral-galaxy' => @spiral_galaxy_data))
      posting_body = response.body

      response = client.get("http://auth-backend.dev/api/v1/users/#{uuid}/identities", {"Authorization" => "Bearer #{@token}"})
      posting_body.must_equal response.body
      identities = JSON.parse(response.body)
      identities['venues'].size.must_equal 2
      identities['venues']['facebook']['id'].must_equal @facebook_data['venue-id']
      identities['venues']['spiral-galaxy']['id'].must_equal @spiral_galaxy_data['venue-id']
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
        user['admin'].must_equal false
      end

      it "has true for the admin field when retrieving info for admins" do
        admin_user = TEST_HELPERS.create_user!(name: 'Adminoo', email: 'jacko@example.com', password: @password, admin: 'true')

        authed_client = Rack::Client.new {
          run Rack::Client::Auth::Basic.new(APP, admin_user['name'], admin_user['password'], true)
        }

        response = authed_client.post("http://auth-backend.dev/api/v1/token")
        response.status.must_equal 201
        admin_token = JSON.parse(response.body)['token']

        response = client.get("http://auth-backend.dev/api/v1/me", 'Authorization' => "Bearer #{admin_token}")
        response.status.must_equal 200
        user = JSON.parse(response.body)
        user['type'].must_equal 'user'
        user['admin'].must_equal true
      end

      it "has a persisted firebase token" do
        user = JSON.parse(client.get("http://auth-backend.dev/api/v1/me", 'Authorization' => "Bearer #{@token}").body)
        firebase_token = user['firebase-token']
        firebase_token.wont_be_empty

        user = JSON.parse(client.get("http://auth-backend.dev/api/v1/me", 'Authorization' => "Bearer #{@token}").body)
        user['firebase-token'].must_equal firebase_token
      end

      it "refreshes firebase token a day before it expires" do
        creation_time = Time.now
        old_firebase_token = nil

        Time.stub :now, creation_time do
          user = JSON.parse(client.get("http://auth-backend.dev/api/v1/me", 'Authorization' => "Bearer #{@token}").body)
          firebase_token = user['firebase-token']
          firebase_token.wont_be_empty
          old_firebase_token = firebase_token
        end

        one_day = 24 * 60 * 60
        nearly_6_days_later = Time.at(creation_time.to_i + (6 * one_day) - 1)

        Time.stub :now, nearly_6_days_later do
          user = JSON.parse(client.get("http://auth-backend.dev/api/v1/me", 'Authorization' => "Bearer #{@token}").body)
          user['firebase-token'].must_equal old_firebase_token
        end

        a_little_more_than_6_days_later = Time.at(nearly_6_days_later + 2)

        Time.stub :now, a_little_more_than_6_days_later do
          user = JSON.parse(client.get("http://auth-backend.dev/api/v1/me", 'Authorization' => "Bearer #{@token}").body)
          user['firebase-token'].wont_be_empty
          user['firebase-token'].wont_equal old_firebase_token
        end
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

          response = client.post("http://auth-backend.dev/api/v1/token/venue/spiral-galaxy", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@venue_data))
          response.status.must_equal 201

          response = client.post("http://auth-backend.dev/api/v1/token/venue/bullshit", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@venue_data))
          response.status.wont_equal 201
        end

        it "adds a player role to the created user" do
          response = client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@venue_data))
          response.status.must_equal 201
          token = JSON.parse(response.body)['token']

          uuid = JSON.parse(client.get("http://auth-backend.dev/api/v1/me", {"Authorization" => "Bearer #{token}"}).body)['uuid']

          connection = Connection.create
          connection.graph.uuids_by_role(@app_token, 'player').must_include uuid
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
            uuid1 = JSON.parse(client.get("http://auth-backend.dev/api/v1/me", {'Authorization' => "Bearer #{@token}"}).body)['uuid']

            response = client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(@venue_data))
            new_token = JSON.parse(response.body)['token']

            uuid2 = JSON.parse(client.get("http://auth-backend.dev/api/v1/me", {'Authorization' => "Bearer #{new_token}"}).body)['uuid']

            uuid1.must_equal uuid2
          end

          it "can translate a list of venue information into QS UUIDs" do
            venue_data2 = {
              "venue-id" => "54632465",
              "name" => "Sam Jackson"
            }

            response = client.post "http://auth-backend/api/v1/uuids/batch", {"Authorization" => "Bearer #{@app_token}"}, JSON.dump('facebook' => [@venue_data, venue_data2])
            response.status.must_equal 200
            uuid_mapping = JSON.parse(response.body)

            response = client.get("http://auth-backend.dev/api/v1/me", 'Authorization' => "Bearer #{@token}")
            uuid1 = JSON.parse(response.body)['uuid']

            token2 = JSON.parse(client.post("http://auth-backend.dev/api/v1/token/venue/facebook", {'Authorization' => "Bearer #{@app_token}"}, JSON.dump(venue_data2)).body)['token']
            response = client.get("http://auth-backend.dev/api/v1/me", 'Authorization' => "Bearer #{token2}")
            uuid2 = JSON.parse(response.body)['uuid']

            uuid_mapping.keys.size.must_equal 1
            facebook_uuids = uuid_mapping['facebook']
            facebook_uuids.keys.size.must_equal 2
            facebook_uuids[@venue_data['venue-id']].must_equal uuid1
            facebook_uuids[venue_data2['venue-id']].must_equal uuid2
          end
        end
      end
    end
  end
end
