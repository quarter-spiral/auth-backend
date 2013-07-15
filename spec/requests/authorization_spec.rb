require_relative '../request_spec_helper.rb'

def gather_response(method, url, options)
  url = File.join("http://auth-backend.dev/", url)
  client.send(method, url, {}, options)
end

def must_be_allowed(method, url, options = {})
  response = gather_response(method, url, options)
  [200, 201].must_include response.status
end

def must_be_forbidden(method, url, options = {})
  response = gather_response(method, url, options)
  response.status.must_equal 403
end

def with_system_level_privileges
  old_token = AuthenticationInjector.token
  AuthenticationInjector.token = get_app_token
  yield
  AuthenticationInjector.token = old_token
end

def retrieve_identities(uuid)
  identities = {}
  with_system_level_privileges do
    identities = JSON.parse(@client.get("/api/v1/users/#{uuid}/identities").body)
  end
  identities
end

def must_have_venue_identity(uuid, venue, identity)
  identities = retrieve_identities(uuid)
  identities['venues'][venue]['id'].must_equal identity['venue-id']
end

def wont_have_venue_identity(uuid, venue, identity)
  identities = retrieve_identities(uuid)
  if identities['venues'][venue]
    identities['venues'][venue]['id'].wont_equal identity['venue-id']
  end
end

def users_wont_exist(venue_ids)
  venue_ids.each do |venue, ids|
    ids.each do |id|
      VenueIdentity.where(venue_id: id['venue_id'], venue: venue).first.must_be_nil
    end
  end
end

def users_must_exist(venue_ids)
  venue_ids.each do |venue, ids|
    ids.each do |id|
      VenueIdentity.where(venue_id: id['venue_id'], venue: venue).first.must_be_nil
    end
  end
end

def user
  @user ||= AUTH_HELPERS.user_data
end

describe Auth::Backend::Apps::API do
  before do
    VenueIdentity.destroy_all

    @facebook_data = {
      "venue-id" => "1234567",
      "name" => "Peter Smith",
      "email" => "peter@example.com"
    }

    @venue_data = {
      "venue-id" => "54632465",
      "name" => "Sam Jackson"
    }

    AUTH_HELPERS.delete_existing_users!
    AUTH_HELPERS.create_user!
    AuthenticationInjector.reset!

    connection = Connection.create

    @user2_options = {name: "AnotherUser", email: "another@example.com", password: "anotherpassword"}
    @user2 = AUTH_HELPERS.create_user!(@user2_options)

    @user3_options = {name: "AndAnotherUser", email: "andanother@example.com", password: "andanotherpassword"}
    @user3 = AUTH_HELPERS.create_user!(@user3_options)

    @yourself = user['uuid']
    @someone_else = @user2['uuid']
  end

  describe "unauthorized" do
    it "cannot retrieve venue identities" do
      must_be_forbidden(:get, "/api/v1/users/#{@yourself}/identities")
    end

    it "cannot retrieve a batch of venue identities" do
      must_be_forbidden(:get, "/api/v1/users/batch/identities", JSON.dump([@yourself]))
    end

    it "cannot attach venue identities to users" do
      must_be_forbidden(:post, "/api/v1/users/#{@yourself}/identities", JSON.dump('facebook' => @facebook_data))
    end

    it "cannot create or get UUIDs for a batch of users identified by their venue identities" do
      must_be_forbidden(:post, "/api/v1/uuids/batch", JSON.dump('facebook' => [@venue_data]))
    end
  end

  describe "authorized as a user" do
    before do
      AuthenticationInjector.token = AUTH_HELPERS.get_token
    end

    after do
      AuthenticationInjector.reset!
    end

    it "can retrieve your own venue identities" do
      must_be_allowed(:get, "/api/v1/users/#{@yourself}/identities")
    end

    it "cannot retrieve anyone else's venue identities" do
      must_be_forbidden(:get, "/api/v1/users/#{@someone_else}/identities")
    end

    it "can retrieve a batch of venue identities of the only user in the batch you want to retrieve is yourself" do
      must_be_allowed(:get, "/api/v1/users/batch/identities", JSON.dump([@yourself]))
    end

    it "cannot retrieve any other batch of venue identities" do
      must_be_forbidden(:get, "/api/v1/users/batch/identities", JSON.dump([@someone_else]))
      must_be_forbidden(:get, "/api/v1/users/batch/identities", JSON.dump([@yourself, @someone_else]))
    end

    it "can attach venue identities to youself" do
      must_be_allowed(:post, "/api/v1/users/#{@yourself}/identities", JSON.dump('facebook' => @facebook_data))
    end

    it "cannot attach venue identities to anyone else" do
      must_be_forbidden(:post, "/api/v1/users/#{@someone_else}/identities", JSON.dump('facebook' => @facebook_data))
    end

    it "cannot create or get UUIDs for a batch of users identified by their venue identities" do
      must_be_forbidden(:post, "/api/v1/uuids/batch", JSON.dump('facebook' => [@venue_data]))
    end
  end

  describe "authenticated as a user" do
    before do
      AuthenticationInjector.token = AUTH_HELPERS.get_token
    end

    after do
      AuthenticationInjector.reset!
    end

    it "can retrieve your own venue identities" do
      must_be_allowed(:get, "/api/v1/users/#{@yourself}/identities")
    end

    it "cannot retrieve anyone else's venue identities" do
      must_be_forbidden(:get, "/api/v1/users/#{@someone_else}/identities")
    end

    it "can retrieve a batch of venue identities of the only user in the batch you want to retrieve is yourself" do
      must_be_allowed(:get, "/api/v1/users/batch/identities", JSON.dump([@yourself]))
    end

    it "cannot retrieve any other batch of venue identities" do
      must_be_forbidden(:get, "/api/v1/users/batch/identities", JSON.dump([@someone_else]))
      must_be_forbidden(:get, "/api/v1/users/batch/identities", JSON.dump([@yourself, @someone_else]))
    end

    it "can attach venue identities to youself" do
      must_be_allowed(:post, "/api/v1/users/#{@yourself}/identities", JSON.dump('facebook' => @facebook_data))
      must_have_venue_identity(@yourself, 'facebook', @facebook_data)
    end

    it "cannot attach venue identities to anyone else" do
      must_be_forbidden(:post, "/api/v1/users/#{@someone_else}/identities", JSON.dump('facebook' => @facebook_data))
      wont_have_venue_identity(@someone_else, 'facebook', @facebook_data)
    end

    it "cannot create or get UUIDs for a batch of users identified by their venue identities" do
      must_be_forbidden(:post, "/api/v1/uuids/batch", JSON.dump('facebook' => [@venue_data]))
      users_wont_exist('facebook' => [@venue_data])
    end
  end

  describe "authenticated as a client with system level privileges" do
    before do
      AuthenticationInjector.token = get_app_token
    end

    after do
      AuthenticationInjector.reset!
    end

    it "can retrieve anyone's venue identities" do
      must_be_allowed(:get, "/api/v1/users/#{@someone_else}/identities")
    end

    it "can retrieve batches of venue identities" do
      must_be_allowed(:get, "/api/v1/users/batch/identities", JSON.dump([@someone_else]))
      must_be_allowed(:get, "/api/v1/users/batch/identities", JSON.dump([@yourself, @someone_else]))
    end

    it "can attach venue identities to anyone" do
      must_be_allowed(:post, "/api/v1/users/#{@someone_else}/identities", JSON.dump('facebook' => @facebook_data))
      must_have_venue_identity(@someone_else, 'facebook', @facebook_data)
    end

    it "can create or get UUIDs for a batch of users identified by their venue identities" do
      must_be_allowed(:post, "/api/v1/uuids/batch", JSON.dump('facebook' => [@venue_data]))
      users_must_exist('facebook' => [@venue_data])
    end
  end
end