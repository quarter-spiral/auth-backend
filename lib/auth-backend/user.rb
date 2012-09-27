require 'active_record'
require 'uuid'

module Auth::Backend
  class User < ::ActiveRecord::Base
    include Songkick::OAuth2::Model::ResourceOwner

    has_secure_password

    attr_accessible :email, :password, :password_confirmation, :name

    validates :name, presence: true, uniqueness: true
    validates :email, presence: true, uniqueness: true

    before_create :set_uuid

    def self.authenticate(name, password)
      find_by_name(name).try(:authenticate, password)
    end

    def private_info
      {
        name: name,
        email: email,
        uuid: uuid
      }
    end

    protected
    def set_uuid
      self.uuid = UUID.new.generate
    end
  end
end