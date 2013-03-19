class AddInvitationNeededFlagToOauth2Clients < ActiveRecord::Migration
  def up
    add_column :oauth2_clients, :needs_invitation, :boolean, default: false
  end

  def down
    remove_column :oauth2_clients, :needs_invitation
  end
end
