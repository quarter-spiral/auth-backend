class AddAutomaticAuthorizationFieldToOauth2Clients < ActiveRecord::Migration
  def change
    add_column :oauth2_clients, :automatic_authorization, :boolean, default: false
  end
end
