module Auth::Backend
  class Metaserver
    def self.setup!
      unless User.where(name: "Jack").first
        u = User.new(name: "Jack", email: "info@quarterspiral.com", password: "quarterspiral", password_confirmation: "quarterspiral")
        u.admin = true
        u.save!
      end

      ENV['QS_FB_APP_ID'] ||= '239267836207466'
      ENV['QS_FB_APP_SECRET'] ||= '509a725c46330afdae2b631d196f2b70'

      apps = [
        {
          name: "Devapp",
          uid: 'f3f2b27f4baed577d2f631e77fd8a068361281ca56edfed07b8cf4392044bd83',
          secret: 'b402c89ec06f9f210f4d6a3d88e71675238bb4a38752375a4fad4c0ab646e122',
          redirect_uri: "#{ENV['QS_SAMPLE_DEVAPP_URL']}/auth/auth_backend/callback",
          needs_invitation: true
        },
        {
          name: "Canvas",
          uid: 'bmycruwwc96b5otil3fipgh8rcoj9z',
          secret: 'rcghf9way9i7lbdzyakaecly5ow9fau',
          redirect_uri: "#{ENV['QS_CANVAS_APP_URL']}/auth/auth_backend/callback",
          automatic_authorization: true
        },
        {
          name: "Playercenter",
          uid: '953apz80uziz6618hkheki4eub4w6cy',
          secret: 'm2ona42hvh7xthauditt63ri21qe1up',
          redirect_uri: "#{ENV['QS_PLAYERCENTER_BACKEND_URL']}"
        },
        {
          name: "Devcenter",
          uid: 'l738roicmwq76lm3h42gxnjfye2253h',
          secret: 'ibeylszv9eicleyhpuwqj819vhkl0l5',
          redirect_uri: "#{ENV['QS_DEVCENTER_BACKEND_URL']}"
        },
        {
          name: "Spiral Galaxy",
          uid: 'nwwd7pi7lqoiw3utuy1qawgl920xw10',
          secret: 'kaqrs5nnau2tjnmo4r2w2q86wue3bo7',
          redirect_uri: "#{ENV['QS_SPIRAL_GALAXY_URL']}/auth/auth_backend/callback"
        }
      ]

      apps.each do |app|
        Songkick::OAuth2::Model::Client.where(client_id: app[:uid]).first.try(:destroy)
        Songkick::OAuth2::Model::Client.where(name: app[:name]).each(&:destroy)
        a = Songkick::OAuth2::Model::Client.new(name: app[:name], redirect_uri: app[:redirect_uri])
        a.save!
        a.client_id = app[:uid]
        a.client_secret = app[:secret]
        a.needs_invitation = true if app[:needs_invitation]
        a.automatic_authorization = true if app[:automatic_authorization]
        a.save!
      end
    end
  end
end
