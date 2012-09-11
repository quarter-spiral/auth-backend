require 'typus/orm/active_record/user/instance_methods'
require 'typus/orm/active_record/user/instance_methods_more'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, as: [:default, :admin]
  attr_accessible :admin, as: :admin
  # attr_accessible :title, :body

  validates :uuid, presence: true, on: :update

  before_create :create_uuid

  include Typus::Orm::ActiveRecord::User::InstanceMethods
  include Typus::Orm::ActiveRecord::User::InstanceMethodsMore

  protected
  def create_uuid
    self.uuid = UUID.new.generate
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    name = conditions.delete(:name)
    where(conditions).where(["lower(name) = :value", { :value => name.downcase }]).first
  end
end
