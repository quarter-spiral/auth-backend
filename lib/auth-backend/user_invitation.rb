require 'active_record'


module Auth::Backend
  class UserInvitation < ::ActiveRecord::Base
    validates :code, presence: true, uniqueness: true
    validates :user_id, uniqueness: true, if: lambda {|user_invitation| user_invitation.user_id}

    belongs_to :user

    before_validation :generate_code

    scope :redeemable, lambda {where("user_invitations.user_id IS NULL")}

    def redeemed?
      !!user_id
    end

    def redeem_for(user)
      return false if redeemed?

      self.user_id = user.id
      self.redeemed_at = Time.now
      save!

      true
    end

    protected
    def generate_code
      self.code ||= generated_code
    end

    def generated_code
      generated_code = nil
      while !generated_code || UserInvitation.where(code: generated_code).first
        generated_code = SecureRandom.hex
      end
      generated_code
    end
  end
end
