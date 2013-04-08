class RemoveUniqueAuthIndice < ActiveRecord::Migration
  INDEX_NAME = 'index_owner_client_pairs'

  def up
    remove_index :oauth2_authorizations, name: INDEX_NAME
    add_index :oauth2_authorizations, [:client_id, :oauth2_resource_owner_type, :oauth2_resource_owner_id], :name => INDEX_NAME
  end

  def down
    remove_index :oauth2_authorizations, name: INDEX_NAME
    add_index :oauth2_authorizations, [:client_id, :oauth2_resource_owner_type, :oauth2_resource_owner_id], :name => INDEX_NAME, :unique => true
  end
end