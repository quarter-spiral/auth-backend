class AddNameAndEmailToVenueIdentities < ActiveRecord::Migration
  def up
    add_column :venue_identities, :name, :string
    add_column :venue_identities, :email, :string

    Auth::Backend::VenueIdentity.reset_column_information
    Auth::Backend::VenueIdentity.all.each do |venue_identity|
      next unless venue_identity.user
      venue_identity.name  = venue_identity.user.name
      venue_identity.email = venue_identity.user.email
      venue_identity.save!
    end
  end

  def down
    remove_column :venue_identities, :name
    remove_column :venue_identities, :email
  end
end
