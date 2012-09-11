Typus.setup do |config|

  # Application name.
  # config.admin_title = "Typus"
  # config.admin_sub_title = ""

  # When mailer_sender is set, password recover is enabled. This email
  # address will be used in Admin::Mailer.
  #
  # Remember to setup the default url options for your specific environment
  # Here is an example of development environment:
  #
  #     config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  #
  # This is a required Rails configuration. In production it must be the actual
  # actual host of your application.
  #
  # config.mailer_sender = "admin@example.com"

  # Define paperclip attachment styles.
  # config.file_preview = :medium
  # config.file_thumbnail = :thumb

  # Authentication: +:none+, +:http_basic+
  # Run `rails g typus:migration` if you need an advanced authentication system.
  # config.authentication = :none
  config.authentication = :devise
  config.user_class_name = "User"


  # Define username and password for +:http_basic+ authentication.
  # config.username = "admin"
  # config.password = "columbia"

  # Define subdomain to use instead of additional path
  # config.subdomain = "admin"

  # Pagination options: These options are passed to the pagination method
  # which can be Kaminari or WillPaginate.
  # config.pagination = { :previous_label => "&larr; " + Typus::I18n.t("Previous"),
  #                       :next_label => Typus::I18n.t("Next") + " &rarr;" }

end

module Typus
  module Authentication
    module Devise

      protected

      include Base

      def admin_user
        current_user
      end

      def authenticate
        authenticate_user!
        redirect_to root_path if current_user && !current_user.admin?
      end

    end
  end
end
