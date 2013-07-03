module Auth
  module Backend
    ROOT = File.expand_path('../', File.dirname(__FILE__))
    TOS_VERSION = '0.0'

    def self.root
      ROOT
    end

    def self.env
      (ENV['RACK_ENV'] || 'development').downcase
    end
  end
end

require 'graph-client'

require 'songkick/oauth2/provider'
require 'firebase_token_generator'

require "auth-backend/version"
require "auth-backend/user"
require "auth-backend/user_invitation"
require "auth-backend/venue_identity"
require "auth-backend/oauth_app"
require "auth-backend/connection"
require "auth-backend/apps"
require "auth-backend/apps/base"
require "auth-backend/apps/authentication"
require "auth-backend/apps/api"
require "auth-backend/apps/admin"
require "auth-backend/apps/test"
require "auth-backend/app"
