class UserRole < ActiveRecord::Base
  attr_accessible :role_id, :user_id, as: [:default, :admin]

  belongs_to :user
  belongs_to :role
end
