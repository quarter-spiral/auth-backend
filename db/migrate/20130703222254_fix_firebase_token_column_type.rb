class FixFirebaseTokenColumnType < ActiveRecord::Migration
  def change
    change_column :users, :firebase_token, :text
  end
end
