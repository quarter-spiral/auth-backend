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

    def private_info
      {
        'name' => name,
        'email' => email,
        'uuid' => uuid,
        'type' => 'user'
      }
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

    protected
    def set_uuid
      self.uuid = UUID.new.generate
    end
  end
end
