class RemoveUniqueAuthIndice < ActiveRecord::Migration
  INDEX_NAME = 'index_owner_client_pairs'

  def up
    begin
      remove_index :oauth2_authorizations, name: INDEX_NAME
    rescue StandardError => e
      puts "Error occured during migration. Most likely just a missing index. Will carry on. Keep an eye on this!"
      p e
    end
    add_index :oauth2_authorizations, [:client_id, :oauth2_resource_owner_type, :oauth2_resource_owner_id], :name => INDEX_NAME
  end

  def down
    remove_index :oauth2_authorizations, name: INDEX_NAME
    add_index :oauth2_authorizations, [:client_id, :oauth2_resource_owner_type, :oauth2_resource_owner_id], :name => INDEX_NAME, :unique => true
  end
end