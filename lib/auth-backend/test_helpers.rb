module Auth::Backend
  class TestHelpers
    USERNAME = "John"
    PASSWORD = "quarterspiral"

    def initialize(app)
      @client = Rack::Client.new {
        run app
      }
      @host = 'http://example.com'

      migrate_db!
      Auth::Backend::Apps.setup!

      delete_existing_users!
      create_user!

      @authed_client = Rack::Client.new {run Rack::Client::Auth::Basic.new(AUTH_APP, USERNAME, PASSWORD, true)}
    end

    def get_token
      JSON.parse(@authed_client.post("#{@host}/api/v1/token").body)['token']
    end

    def user_data
      JSON.parse(@client.get("#{@host}/_tests_/users").body).detect {|u| u['user']['name'] == USERNAME}['user']
    end

    def cleanup!
      `rm -rf #{File.dirname(@db_file)}` unless @db_dir_existed
    end

    protected
    def migrate_db!
      Apps.setup_db!
      @db_file = ENV['DATABASE_URL'].gsub(/^sqlite3:\//, '')
      @db_dir_existed = File.directory?(File.dirname(@db_file))
      `mkdir -p #{File.dirname(@db_file)}`
      `touch #{@db_file}`
      migration_dir = `bundle show --paths auth-backend`.chomp
      ActiveRecord::Migrator.migrate(migration_dir, nil)
    end

    def delete_existing_users!
      JSON.parse(@client.get("#{@host}/_tests_/users").body).each do |user|
        @client.delete("#{@host}/_tests_/users/#{user['user']['id']}")
      end
    end

    def create_user!
      user  = JSON.parse(@client.post("#{@host}/_tests_/users", {}, name: USERNAME, password: PASSWORD, password_confirmation: PASSWORD, email: 'john@quarterspiral.com', admin: 'true').body)
    end
  end
end
