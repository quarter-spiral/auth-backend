class CreateInvitationsForAdmins < ActiveRecord::Migration
  def up
    Auth::Backend::UserInvitation.transaction do
      Auth::Backend::User.where(admin: true).each do |user|
        Auth::Backend::UserInvitation.create!(user_id: user.id, redeemed_at: Time.now)
      end
    end
  end

  def down
    Auth::Backend::UserInvitation.destroy_all
  end
end
