require 'active_record'


module Auth::Backend
  class UserInvitation < ::ActiveRecord::Base
    validates :code, presence: true, uniqueness: true
    validates :user_id, uniqueness: true, if: lambda {|user_invitation| user_invitation.user_id}

    belongs_to :user

    before_validation :generate_code

    def redeemed?
      !!user_id
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
