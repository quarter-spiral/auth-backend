module Auth::Backend
  module Apps
    def self.setup!
      setup_db!
      setup_warden!
      setup_logging!
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
        user.id
      end

      Warden::Manager.serialize_from_session do |id|
        User.find(id)
      end
    end

    def self.setup_db!
      ENV['DATABASE_URL'] = nil if ENV['DATABASE_URL'].blank?

      case Auth::Backend.env
      when 'production'
        raise "No database set!" unless ENV['DATABASE_URL']
      when 'test'
        ENV['DATABASE_URL'] ||= 'sqlite3:/db/test.db'
      else
        ENV['DATABASE_URL'] ||= 'sqlite3:/db/development.db'
      end

      Authentication.set :database, ENV['DATABASE_URL']
    end

    def self.setup_logging!
      dir = File.expand_path('./logs/', Auth::Backend.root)
      Dir.mkdir(dir) unless File.directory?(dir)
      path = File.expand_path("./#{Auth::Backend.env}.log", dir)

      ActiveRecord::Base.logger = Logger.new(File.open(path, 'a'))
    end
  end
end
