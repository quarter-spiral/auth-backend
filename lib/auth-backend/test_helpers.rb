require 'nokogiri'

module Auth::Backend
  class TestHelpers
    DEFAULT_USER = {
      name: "John",
      email: "john@example.com",
      admin: 'true',
      password: 'quarterspiral'
    }

    attr_reader :client

    def initialize(app)
      @app = app
      @client = Rack::Client.new {
        run app
      }
      @host = 'http://example.com'

      migrate_db!
      Auth::Backend::Apps.setup!

      OauthApp.destroy_all
      VenueIdentity.destroy_all
      Auth::Backend::Apps.setup_oauth_api_client_app!

      delete_existing_users!
      user = create_user!

      @authed_client = Rack::Client.new {run Rack::Client::Auth::Basic.new(app, user['name'], user['password'], true)}
    end

    def get_token
      JSON.parse(@authed_client.post("#{@host}/api/v1/token").body)['token']
    end

    def get_app_token(app_id, app_secret)
      app = @app
      authed_client = Rack::Client.new {run Rack::Client::Auth::Basic.new(app, app_id, app_secret, true)}
      JSON.parse(authed_client.post("#{@host}/api/v1/token/app").body)['token']
    end

    def expire_all_tokens!
      Songkick::OAuth2::Model::Authorization.destroy_all
    end

    def user_data(name = nil)
      name ||= DEFAULT_USER[:name]
      JSON.parse(@client.get("#{@host}/_tests_/users").body).detect {|u| u['user']['name'] == name}['user']
    end

    def cleanup!
      `rm -rf #{File.dirname(@db_file)}` unless @db_dir_existed
    end

    def migrate_db!
      Apps.setup_db!
      ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths)
    end

    def delete_existing_users!
      JSON.parse(@client.get("#{@host}/_tests_/users").body).each do |user|
        @client.delete("#{@host}/_tests_/users/#{user['user']['id']}")
      end
    end

    def create_user!(options = {})
      options = DEFAULT_USER.merge(options)

      user = JSON.parse(client.post("/_tests_/users", {}, options).body)['user']

      user['password'] = options[:password]
      user
    end

    def login(user, password)
      response = client.post("http://auth-backend.dev/login", {}, name: user, password: password)
      cookie = response.headers["Set-Cookie"]
    end

    def delete_user(id)
      client.delete("/_tests_/users/#{id}")
    end

    def list_users
      JSON.parse(client.get("/_tests_/users").body).map {|u| u['user']}
    end

    def create_app!
      password = 'testtest'
      name = nil
      while !name || User.where(name: name).first
        name = (0...12).map{65.+(rand(25)).chr}.join
      end
      app_name = "app-for-#{name}"
      user = create_user!(name: name, email: "#{name}@example.com", password: password, admin: 'true')

      cookie = login(user['name'], user['password'])
      response = client.post('/admin/apps', {'Cookie' => cookie}, 'app[name]' => app_name, 'app[redirect_uri]' => 'http://example.com/some_app')
      cookie = response['Set-Cookie']
      response = client.get('/admin/apps', 'Cookie' => cookie)
      apps = Nokogiri::HTML(response.body)

      secret = apps.css('.alert.alert-success').first.text.gsub(/.*App secret is: /m, '').gsub(/ .*$/, '').chomp
      id = apps.css("td:contains('#{app_name}')").first.parent.css('td')[1].text
      {id: id, secret: secret}
    end
  end
end
