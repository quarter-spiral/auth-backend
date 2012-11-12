class RenameGalaxySpiralToSpiralGalaxy < ActiveRecord::Migration
  def up
    i = 0
    Auth::Backend::VenueIdentity.transaction do
      Auth::Backend::VenueIdentity.where(venue: 'galaxy-spiral').each do |venue_identity|
        venue_identity.venue = 'spiral-galaxy'
        venue_identity.save!
        i += 1
      end
    end
    puts "#{i} entries updates"
  end

  def down
    Auth::Backend::VenueIdentity.transaction do
      i = 0
      Auth::Backend::VenueIdentity.where(venue: 'spiral-galaxy').each do |venue_identity|
        venue_identity.venue = 'galaxy-spiral'
        venue_identity.save!
        i += 1
      end
    end
    puts "#{i} entries updates"
  end
end
