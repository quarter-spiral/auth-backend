class AddFirebaseTokenFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :firebase_token, :string
    add_column :users, :firebase_token_expires_at, :integer
  end
end
