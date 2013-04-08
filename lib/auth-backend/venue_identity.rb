require 'active_record'

module Auth::Backend
  class VenueIdentity < ::ActiveRecord::Base
    attr_accessible :venue, :venue_id, :user_id, :name, :email

    validates :venue, inclusion: {in: %w{facebook spiral-galaxy embedded}}

    belongs_to :user
  end
end

