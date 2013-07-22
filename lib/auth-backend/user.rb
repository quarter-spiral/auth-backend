require 'active_record'
require 'uuid'

module Auth::Backend
  class User < ::ActiveRecord::Base
    include Songkick::OAuth2::Model::ResourceOwner

    has_secure_password

    attr_accessible :email, :password, :password_confirmation, :name

    validates :name, presence: true, uniqueness: true
    validates :email, presence: true, uniqueness: true

    has_many :venue_identities, dependent: :destroy
    has_one :user_invitation, dependent: :destroy

    before_create :set_uuid

    def self.authenticate(name, password)
      find_by_name(name).try(:authenticate, password)
    end

    def private_identity
      {
        'name' => name,
        'email' => email,
        'uuid' => uuid,
        'type' => 'user',
        'admin' => admin
      }
    end

    def private_info
      private_identity.merge(
        'firebase-token' => firebase_token
      )
    end

    def venues
      Hash[venue_identities.map {|vi| [vi.venue, {id: vi.venue_id, name: vi.name}]}]
    end

    def invited?
      user_invitation
    end

    def password_digest=(digest)
      write_attribute(:password_digest, digest.force_encoding('utf-8'))
    end

    def accepted_current_tos?
      accepted_tos_version && accepted_tos_version == TOS_VERSION
    end

    def accept_current_tos!(accepted_version)
      self.accepted_tos_version = accepted_version if accepted_version == TOS_VERSION
    end

    def firebase_token(firebase_secret = nil)
      token = read_attribute(:firebase_token)

      return token if token && !firebase_token_expired?

      firebase_secret ||= ENV['QS_FIREBASE_SECRET']

      one_day = 24 * 60 * 60
      in_one_week =  Time.now.to_i + (one_day * 7)

      if firebase_secret
        generator = Firebase::FirebaseTokenGenerator.new(firebase_secret)
        token = generator.create_token(private_identity, :expires => in_one_week)
      else
        token = "123-456-#{rand(999)}"
      end

      write_attribute(:firebase_token_expires_at, in_one_week)
      write_attribute(:firebase_token, token)
      save!(validate: false) unless new_record?
      token
    end

    def firebase_token_expired?
      # It's expired when it's valid for less than a day
      in_one_day = Time.now.to_i + (24 * 60 * 60)
      !firebase_token_expires_at || firebase_token_expires_at < in_one_day
    end

    def refresh_firebase_token!(firebase_secret = nil)
      self.firebase_token_expires_at = nil
      self.firebase_token = nil
      firebase_token(firebase_secret)
    end

    protected
    def set_uuid
      self.uuid = UUID.new.generate
    end
  end
end
