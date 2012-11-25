module Auth::Backend
  module Apps
    def self.setup!
      setup_db!
      setup_warden!
      setup_logging!

      migrate_db! if ENV['RACK_ENV'] == 'test'

      setup_oauth_api_client_app!
    end

    def self.setup_warden!
      Warden::Strategies.add(:password) do
        def valid?
          params['name'] || params['password']
        end

        def authenticate!
          u = Auth::Backend::User.authenticate(params['name'], params['password'])
          u.nil? ? fail!("Could not log in") : success!(u)
        end
      end

      Warden::Manager.serialize_into_session do |user|
        {user: user.id, admin_user: user.admin? ? user.id : nil}
      end

      Warden::Manager.serialize_from_session do |data|
        #TODO: Remove once all sessions are transformed
        data = {user: data} unless data.kind_of?(Hash)
        User.find(data[:user])
      end
    end

    def self.setup_db!
      ENV['DATABASE_URL'] = nil if ENV['DATABASE_URL'].blank?

      case Auth::Backend.env
      when 'production'
        raise "No database set!" unless ENV['DATABASE_URL']
      when 'test'
        ENV['DATABASE_URL'] ||= 'sqlite3:/:memory:'
      else
        ENV['DATABASE_URL'] ||= 'sqlite3:/db/development.db'
      end

      Authentication.set :database, ENV['DATABASE_URL']
    end

    def self.migrate_db!
      migration_dir = `bundle show --paths auth-backend`.chomp
      migration_dirs = migration_dir.split("\n")
      if migration_dirs.length > 1
        migration_dir = migration_dirs.detect {|d| d =~ /auth-backend$/}
      end
      ActiveRecord::Migrator.migrate([migration_dir])
    end

    def self.setup_logging!
      dir = File.expand_path('./logs/', Auth::Backend.root)
      Dir.mkdir(dir) unless File.directory?(dir)
      path = File.expand_path("./#{Auth::Backend.env}.log", dir)

      ActiveRecord::Base.logger = Logger.new(File.open(path, 'a'))
    end

    def self.setup_oauth_api_client_app!
      unless OauthApp.api_client
        OauthApp.create_api_client
      end
    end
  end
end
