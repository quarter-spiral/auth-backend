require_relative '../request_spec_helper'

require 'cgi'

def send_auth_for_app(app, cookie)
  url = CGI::escape(app.redirect_uri)
  client.get "/oauth/authorize?response_type=code&client_id=#{app.client_id}&redirect_uri=#{url}", {"Cookie" => cookie}
end

describe "Test Only Interface" do
  before do
    User.destroy_all
  end

  it "can create users" do
    user = TEST_HELPERS.create_user!
    User.count.must_equal 1
    user['id'].wont_be_nil
  end

  it "can delete users" do
    user = TEST_HELPERS.create_user!
    TEST_HELPERS.delete_user(user['id'])
    User.count.must_equal 0
  end

  it "can list users" do
    user = TEST_HELPERS.create_user!(name: "John One", email: "johnone@example.com")
    user = TEST_HELPERS.create_user!(name: "John Two", email: "johntwo@example.com")

    users = TEST_HELPERS.list_users
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

    user = TEST_HELPERS.create_user!
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
    @user = TEST_HELPERS.create_user!(password: @password, admin: 'false')

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

  describe "not invited user" do
    before do
      User.destroy_all
      UserInvitation.destroy_all
      @password = 'schackalacka'
      @user = TEST_HELPERS.create_user!(password: @password, admin: 'false', no_invitation: true)
      Apps.setup_oauth_api_client_app!
    end

    it "does not redirects to /invite when user not invited yet" do
      response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password)
      cookie = response.headers["Set-Cookie"]
      response = client.get("http://auth-backend.dev/", {'Cookie' => cookie})
      response.status.must_equal 200
    end

    describe "with an app that needs an invitation and one which does not" do
      before do
        params = {
          name: "AppNeddingInvitation",
          redirect_uri: "http://example.com/withinvitation"
        }
        @app_that_needs_invitation = OauthApp.new(params)
        @app_that_needs_invitation.needs_invitation = true
        @app_that_needs_invitation.save!

        params = {
          name: "AppNeedsNoInvitation",
          redirect_uri: "http://example.com/noinvitation",
        }
        @app_that_does_not_need_invitation = OauthApp.new(params)
        @app_that_does_not_need_invitation.save!

        user = User.find(@user['id'])
        user.grant_access!(@app_that_needs_invitation)
        user.grant_access!(@app_that_does_not_need_invitation)
      end

      after do
        @app_that_needs_invitation.destroy
        @app_that_does_not_need_invitation.destroy
      end

      it "can not redeem an invalid invitation code" do
        response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password)
        cookie = response.headers["Set-Cookie"]
        response = client.post("http://auth-backend.dev/invite", {'Cookie' => cookie}, code: 'does-not-exist')
        cookie = response.headers["Set-Cookie"]
        response = client.get('http://auth-backend.dev/profile', {'Cookie' => cookie})
        response.status.must_equal(200)

        response = send_auth_for_app(@app_that_needs_invitation, cookie)
        must_redirect_to('/invite', response)
      end

      it "can not reddem an invitation code twice" do
        invitation = UserInvitation.create!

        response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password)
        cookie = response.headers["Set-Cookie"]
        response = client.post("http://auth-backend.dev/invite", {'Cookie' => cookie}, code: invitation.code)

        user2 = TEST_HELPERS.create_user!(name: @user['name'].reverse, email: @user['email'].reverse, password: @password, admin: 'false', no_invitation: true)
        user2_model = User.find(user2['id'])
        user2_model.grant_access!(@app_that_needs_invitation)

        response = client.post("http://auth-backend.dev/login", {}, name: user2['name'], password: @password)
        cookie = response.headers["Set-Cookie"]
        response = client.post("http://auth-backend.dev/invite", {'Cookie' => cookie}, code: invitation.code)

        cookie = response.headers["Set-Cookie"]
        response = send_auth_for_app(@app_that_needs_invitation, cookie)

        must_redirect_to('/invite', response)
      end

      it "can redeem a valid invitation code" do
        response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password)
        cookie = response.headers["Set-Cookie"]

        invitation = UserInvitation.create!
        response = client.post("http://auth-backend.dev/invite", {'Cookie' => cookie}, code: invitation.code)
        cookie = response.headers["Set-Cookie"]

        response = send_auth_for_app(@app_that_needs_invitation, cookie)
        must_redirect_to(@app_that_needs_invitation.redirect_uri, response)

        invitation.reload
        invitation.user_id.wont_be_nil
        invitation.redeemed_at.wont_be_nil
      end

      it "sends to /invite when authorizing an app that needs an invitation" do
        response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password)
        cookie = response.headers["Set-Cookie"]

        response = send_auth_for_app(@app_that_needs_invitation, cookie)
        must_redirect_to('/invite', response)
      end

      it "redirects to the app when the user has an invitation and the app neds an invitation" do
        response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password)
        cookie = response.headers["Set-Cookie"]

        invitation = UserInvitation.create!
        response = client.post("http://auth-backend.dev/invite", {'Cookie' => cookie}, code: invitation.code)
        cookie = response.headers["Set-Cookie"]

        response = send_auth_for_app(@app_that_needs_invitation, cookie)
        must_redirect_to(@app_that_needs_invitation.redirect_uri, response)
      end

      it "redirects to the app when the app does not need an invitation" do
        response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password)
        cookie = response.headers["Set-Cookie"]

        response = send_auth_for_app(@app_that_does_not_need_invitation, cookie)
        must_redirect_to(@app_that_does_not_need_invitation.redirect_uri, response)
      end

      it "has to accept terms and conditions" do
        User.destroy_all
        @user = TEST_HELPERS.create_user!(password: @password, admin: 'false', tos_not_accepted: true)
        user = User.find(@user['id'])
        user.grant_access!(@app_that_does_not_need_invitation)

        response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password)
        cookie = response.headers["Set-Cookie"]

        response = client.get("http://auth-backend.dev/", {'Cookie' => cookie})
        must_redirect_to('/accept-tos', response)

        response = send_auth_for_app(@app_that_does_not_need_invitation, cookie)
        cookie = response.headers["Set-Cookie"]
        # this should actually set the target to redirect to after accepting the TOS to the
        # auth backend OAUTH handler (at /oauth/authorize)...
        must_redirect_to('/accept-tos', response)

        client.post("http://auth-backend.dev/accept-tos", {'Cookie' => cookie})
        # this should NOT change the redirect target...
        response = send_auth_for_app(@app_that_does_not_need_invitation, cookie)
        cookie = response.headers["Set-Cookie"]
        must_redirect_to('/accept-tos', response)

        response = client.post("http://auth-backend.dev/accept-tos", {'Cookie' => cookie}, {"accept-tos" => Auth::Backend::TOS_VERSION})
        cookie = response.headers["Set-Cookie"]
        # and now we should be redirected to the app as we've accepted the TOS
        must_redirect_to("/oauth/authorize", response)

        response = send_auth_for_app(@app_that_does_not_need_invitation, cookie)
        must_redirect_to(@app_that_does_not_need_invitation.redirect_uri, response)
      end
    end
  end

  it "redirects to root after a successful login" do
    response = client.post("http://auth-backend.dev/login", {}, name: @user['name'], password: @password)
    must_redirect_to('/', response)
    cookie = response.headers["Set-Cookie"]

    response = client.get("http://auth-backend.dev/", {'Cookie' => cookie})
    response.status.must_equal 200
  end
end