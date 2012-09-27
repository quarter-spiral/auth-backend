module Auth::Backend
  class Metaserver
    def self.setup!
      unless User.where(name: "Jack").first
        u = User.new(name: "Jack", email: "info@quarterspiral.com", password: "quarterspiral", password_confirmation: "quarterspiral")
        u.admin = true
        u.save!
      end


      uid = 'f3f2b27f4baed577d2f631e77fd8a068361281ca56edfed07b8cf4392044bd83'
      secret = 'b402c89ec06f9f210f4d6a3d88e71675238bb4a38752375a4fad4c0ab646e122'
      redirect_uri = "#{ENV['QS_SAMPLE_DEVAPP_URL']}/auth/auth_backend/callback"

      Songkick::OAuth2::Model::Client.where(client_id: uid).first.try(:destroy)
      a = Songkick::OAuth2::Model::Client.new(name: "Sample Devapp", redirect_uri: redirect_uri)
      a.save!
      a.client_id = uid
      a.client_secret = secret
      a.save!
    end
  end
end