require_relative '../request_spec_helper'

describe "Administration" do
  before do
    User.destroy_all
    @password = 'schackalacka'
    @user = TEST_HELPERS.create_user!(password: @password, admin: 'false')

    Apps.setup_oauth_api_client_app!
  end

  it "can't reach the admin interface when not logged in" do
    response = client.get("http://auth-backend.dev/admin")
    must_redirect_to('/login', response)
  end

   describe "logged in" do
     before do
       @cookie = TEST_HELPERS.login(@user['name'], @password)
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

  it "can't impersonate another user" do
    password2 = 'schackalacka'
    user2 = TEST_HELPERS.create_user!(name: @user['name'].reverse, email: "2#{@user['email']}", password: password2, admin: 'false')

    response = client.post("http://auth-backend.dev/admin/users/#{user2['id']}/impersonate", 'Cookie' => @cookie)
    response.headers['Set-Cookie'].must_be_nil
  end

  describe "with a logged in admin" do
    before do
      User.destroy_all
      @user = TEST_HELPERS.create_user!(name: @user['name'], password: @password, admin: 'true')
      @cookie = TEST_HELPERS.login(@user['name'], @password)
    end

    it "can reach the admin interface" do
      response = client.get("http://auth-backend.dev/admin", 'Cookie' => @cookie)
      response.status.must_equal 200
    end

    describe "impersonating of another user" do
      before do
        password2 = 'schackalacka'
        @user2 = TEST_HELPERS.create_user!(name: @user['name'].reverse, email: "2#{@user['email']}", password: password2, admin: 'false')

        response = client.post("http://auth-backend.dev/admin/users/#{@user2['id']}/impersonate", 'Cookie' => @cookie)
        @new_cookie = response.headers['Set-Cookie']
        @new_cookie.wont_be_nil
      end

      it "works" do
        response = client.get("http://auth-backend.dev/profile", 'Cookie' => @new_cookie)
        response.status.must_equal 200
        response.body.must_include @user2['name']
        response.body.wont_include @user['name']
      end

      it "can be reversed even if the impersonated user is not an admin" do
        response = client.post("http://auth-backend.dev/admin/users/#{@user['id']}/impersonate", 'Cookie' => @new_cookie)
        new_new_cookie = response.headers['Set-Cookie']
        new_new_cookie.wont_be_nil

        response = client.get("http://auth-backend.dev/profile", 'Cookie' => new_new_cookie)
        response.status.must_equal 200
        response.body.must_include @user['name']
        response.body.wont_include @user2['name']
      end
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
            @users << TEST_HELPERS.create_user!(name: "Tester #{i}", email: "tester-#{i}@example.com")
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

          last_user = TEST_HELPERS.list_users.detect {|u| u['id'] == last_user['id']}
          last_user['name'].must_equal 'Updated User'
        end

        it "can delete a user" do
          last_user = @users.last
          response = client.delete("http://auth-backend.dev/admin/users/#{last_user['id']}", {'Cookie' => @cookie})

          users = TEST_HELPERS.list_users.map {|e| e['id']}
          users.wont_include last_user['id']
        end

        it "can create a user" do
          users = TEST_HELPERS.list_users.map {|e| e['name']}
          users.wont_include 'John New'

          client.post("http://auth-backend.dev/admin/users", {'Cookie' => @cookie}, 'user[name]' => 'John New', 'user[email]' => 'john.new@example.com', 'user[password]' => 'test', 'user[password_confirmation]' => 'test')

          users = TEST_HELPERS.list_users.map {|e| e['name']}
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
