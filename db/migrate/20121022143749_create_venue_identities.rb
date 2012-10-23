class CreateVenueIdentities < ActiveRecord::Migration
  def change
    create_table(:venue_identities) do |t|
      t.string :venue,    null: false
      t.string :venue_id, null: false
      t.integer :user_id, null: false
    end

    add_index :venue_identities, :venue
    add_index :venue_identities, :venue_id
    add_index :venue_identities, :user_id
    add_index :venue_identities, [:venue, :venue_id], unique: true
    add_index :venue_identities, [:venue, :user_id], unique: true
  end
end
