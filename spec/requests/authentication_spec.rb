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

def add_user(options = {})
  options[:name] ||= "John"
  options[:email] ||= "john@example.com"
  options[:password] ||= "testtest"

  JSON.parse(client.post("#{TEST_MOUNT}/users", {}, options).body)['user']
end

def delete_user(id)
  client.delete("#{TEST_MOUNT}/users/#{id}")
end

def list_users
  JSON.parse(client.get("#{TEST_MOUNT}/users").body).map {|u| u['user']}
end

def must_redirect_to(path, response)
  response.status.must_equal 302
  URI.parse(response.headers['Location']).path.must_equal path
end

def login
  response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password)
  cookie = response.headers["Set-Cookie"]
end

describe "Test Only Interface" do
  before do
    User.destroy_all
  end

  it "can create users" do
    user = add_user
    User.count.must_equal 1
    user['id'].wont_be_nil
  end

  it "can delete users" do
    user = add_user
    delete_user(user['id'])
    User.count.must_equal 0
  end

  it "can list users" do
    user = add_user(name: "John One", email: "johnone@example.com")
    user = add_user(name: "John Two", email: "johntwo@example.com")

    users = list_users
    users.size.must_equal 2
    john1 = users.detect {|u| u['name'] == 'John One'}
    john2 = users.detect {|u| u['name'] == 'John Two'}
    john1['email'].must_equal "johnone@example.com"
    john2['email'].must_equal "johntwo@example.com"
  end

  it "does not work when test mode is not explicitly enabled" do
    normal_client = Rack::Client.new {run App.new}
    response = normal_client.post("#{TEST_MOUNT}/users", {}, name: "John", email: 'john@example.com', password: 'testtest', password_confirmation: 'testtest')
    User.count.must_equal 0
    response.status.must_equal 404

    user = add_user
    response = normal_client.delete("#{TEST_MOUNT}/users/#{user['id']}")
    User.count.must_equal 1
    response.status.must_equal 404

    response = normal_client.get("#{TEST_MOUNT}/users")
    response.status.must_equal 404
  end
end

describe "Authentication" do
  before do
    User.destroy_all
    @password = 'schackalacka'
    @user = add_user(password: @password)

    Apps.setup_oauth_api_client_app!
  end

  it "is being redirected to login when not logged in" do
    response = client.get('http://auth-backend.dev/')
    must_redirect_to('/login', response)
  end


  it "redirects to /login after a failed login" do
    response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password.reverse)
    response.status.must_equal 401

    response = client.get('http://auth-backend.dev/')
    must_redirect_to('/login', response)
  end

  it "redirects to root after a successful login" do
    response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password)
    must_redirect_to('/', response)
    cookie = response.headers["Set-Cookie"]

    response = client.get("http://auth-backend.dev/", {'Cookie' => cookie})
    response.status.must_equal 200
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
      User.destroy_all
      @user = add_user(name: @user['name'], password: @password, admin: 'true')
      cookie = login
      Songkick::OAuth2::Model::Client.destroy_all
      response = client.post('http://auth-backend.dev/admin/apps', {'Cookie' => cookie}, 'app[name]' => 'Some App', 'app[redirect_uri]' => 'http://example.com/some_app')
      cookie = response['Set-Cookie']
      response = client.get('http://auth-backend.dev/admin/apps', 'Cookie' => cookie)
      apps = Nokogiri::HTML(response.body)
      secret = apps.css('.alert.alert-success').first.text.gsub(/.*App secret is: /m, '').gsub(/ .*$/, '').chomp
      id = apps.css("td:contains('Some App')").first.parent.css('td')[1].text

      authed_client = Rack::Client.new {
        run Rack::Client::Auth::Basic.new(APP, id, secret, true)
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

  describe "Administration" do
    it "can't reach the admin interface when not logged in" do
      response = client.get("http://auth-backend.dev/admin")
      must_redirect_to('/login', response)
    end

     describe "logged in" do
       before do
         @cookie = login
       end
     end

    it "can't reach the admin interface when logged in but not an admin" do
      response = client.get("http://auth-backend.dev/admin", 'Cookie' => @cookie)
      must_redirect_to('/login', response)
    end

    it "can't reach the user administration" do
      response = client.get("http://auth-backend.dev/admin/users", 'Cookie' => @cookie)
      must_redirect_to('/login', response)
    end

    describe "with a logged in admin" do
      before do
        User.destroy_all
        @user = add_user(name: @user['name'], password: @password, admin: 'true')
        @cookie = login
      end

      it "can reach the admin interface" do
        response = client.get("http://auth-backend.dev/admin", 'Cookie' => @cookie)
        response.status.must_equal 200
      end

      describe "user administration" do
        it "can reach the user administration" do
          response = client.get("http://auth-backend.dev/admin/users", 'Cookie' => @cookie)
          response.status.must_equal 200
        end

        describe "with some users" do
          before do
            @users = [@user]
            5.times do |i|
              @users << add_user(name: "Tester #{i}", email: "tester-#{i}@example.com")
            end
          end

          it "can list all users" do
            response = client.get("http://auth-backend.dev/admin/users", 'Cookie' => @cookie)
            page = Nokogiri::HTML(response.body)
            @users.each do |user|
              page.css("a[href='/admin/users/#{user['id']}/edit']").wont_be_empty
            end
          end

          it "can edit a user" do
            last_user = @users.last
            response = client.put("http://auth-backend.dev/admin/users/#{last_user['id']}", {'Cookie' => @cookie}, 'user[name]' => 'Updated User')

            last_user = list_users.detect {|u| u['id'] == last_user['id']}
            last_user['name'].must_equal 'Updated User'
          end

          it "can delete a user" do
            last_user = @users.last
            response = client.delete("http://auth-backend.dev/admin/users/#{last_user['id']}", {'Cookie' => @cookie})

            users = list_users.map {|e| e['id']}
            users.wont_include last_user['id']
          end

          it "can create a user" do
            users = list_users.map {|e| e['name']}
            users.wont_include 'John New'

            client.post("http://auth-backend.dev/admin/users", {'Cookie' => @cookie}, 'user[name]' => 'John New', 'user[email]' => 'john.new@example.com', 'user[password]' => 'test', 'user[password_confirmation]' => 'test')

            users = list_users.map {|e| e['name']}
            users.must_include 'John New'
          end
        end
      end


      describe "apps administration" do
        before do
          Songkick::OAuth2::Model::Client.destroy_all
        end

        it "can reach the apps administration" do
          response = client.get("http://auth-backend.dev/admin/apps", 'Cookie' => @cookie)
          response.status.must_equal 200
        end

        it "can create an app" do
          response = client.get('http://auth-backend.dev/admin/apps', 'Cookie' => @cookie)
          apps = Nokogiri::HTML(response.body)
          apps.css("td:contains('Some App')").must_be_empty

          client.post('http://auth-backend.dev/admin/apps', {'Cookie' => @cookie}, 'app[name]' => 'Some App', 'app[redirect_uri]' => 'http://example.com/some_app')

          response = client.get('http://auth-backend.dev/admin/apps', 'Cookie' => @cookie)
          apps = Nokogiri::HTML(response.body)
          apps.css("td:contains('Some App')").wont_be_empty
        end

        describe "with an app" do
          before do
            Songkick::OAuth2::Model::Client.destroy_all
            client.post('http://auth-backend.dev/admin/apps', {'Cookie' => @cookie}, 'app[name]' => 'Some App', 'app[redirect_uri]' => 'http://example.com/some_app')
            response = client.get('http://auth-backend.dev/admin/apps', 'Cookie' => @cookie)
            apps = Nokogiri::HTML(response.body)
            links = apps.css("tr a[href]")
            links.detect {|link| link['href'] =~ /^\/admin\/apps\/(\d+)\/edit$/}
            @app_id = $1.to_i
          end

          it "can edit a user" do
            response = client.get('http://auth-backend.dev/admin/apps', 'Cookie' => @cookie)
            apps = Nokogiri::HTML(response.body)
            apps.css("td:contains('Some App')").wont_be_empty
            apps.css("td:contains('Edited App')").must_be_empty

            client.put("http://auth-backend.dev/admin/apps/#{@app_id}", {'Cookie' => @cookie}, 'app[name]' => 'Edited App')

            response = client.get('http://auth-backend.dev/admin/apps', 'Cookie' => @cookie)
            apps = Nokogiri::HTML(response.body)
            apps.css("td:contains('Some App')").must_be_empty
            apps.css("td:contains('Edited App')").wont_be_empty
          end

          it "can delete a user" do
            response = client.get('http://auth-backend.dev/admin/apps', 'Cookie' => @cookie)
            apps = Nokogiri::HTML(response.body)
            apps.css("td:contains('Some App')").wont_be_empty

            client.delete("http://auth-backend.dev/admin/apps/#{@app_id}", 'Cookie' => @cookie)

            response = client.get('http://auth-backend.dev/admin/apps', 'Cookie' => @cookie)
            apps = Nokogiri::HTML(response.body)
            apps.css("td:contains('Some App')").must_be_empty
          end
        end
      end
    end
  end
end

