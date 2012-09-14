if ENV['RUNS_ON_METASERVER'] && Rails.env == 'development'
  unless User.where(name: "Jack").first
    u = User.new(name: "Jack", email: "info@quarterspiral.com", password: "quarterspiral", password_confirmation: "quarterspiral")
    u.admin = true
    u.save!
  end


  uid = 'f3f2b27f4baed577d2f631e77fd8a068361281ca56edfed07b8cf4392044bd83'
  secret = 'b402c89ec06f9f210f4d6a3d88e71675238bb4a38752375a4fad4c0ab646e122'
  redirect_uri = "#{ENV['QS_SAMPLE_DEVAPP_URL']}/auth/auth_backend/callback"

  Doorkeeper::Application.where(uid: uid).first.try(:destroy)
  a = Doorkeeper::Application.new(name: "Sample Devapp", redirect_uri: redirect_uri)
  a.save!
  a.uid = uid
  a.secret = secret
  a.save!
end
