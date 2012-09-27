class CreateUsers < ActiveRecord::Migration
  def change
    create_table(:users) do |t|
      t.string :name
      t.string :email,           null: false, default: ""
      t.string :password_digest, null: false, default: ""
      t.string :uuid,            null: false
    end
  end
end
