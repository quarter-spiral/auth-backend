class CreateUserInvitations < ActiveRecord::Migration
  def up
    create_table :user_invitations do |t|
      t.string   :code
      t.integer  :user_id
      t.datetime :redeemed_at

      t.timestamps
    end
  end

  def down
    drop_table :user_invitations
  end
end
