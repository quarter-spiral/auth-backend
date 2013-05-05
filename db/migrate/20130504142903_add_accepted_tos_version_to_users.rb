class AddAcceptedTosVersionToUsers < ActiveRecord::Migration
  def change
    add_column :users, :accepted_tos_version, :string
  end
end
