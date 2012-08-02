class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
  # attr_accessible :title, :body

  validates :uuid, presence: true, on: :update

  before_create :create_uuid

  has_many :user_roles
  has_many :roles, through: :user_roles

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