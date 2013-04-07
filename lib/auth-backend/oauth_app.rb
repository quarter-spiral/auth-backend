require 'delegate'

class Songkick::OAuth2::Model::Client
  include ::Songkick::OAuth2::Model::ResourceOwner

  def private_info
    {
      'type' => 'app'
    }
  end
end

module Auth::Backend
  class OauthApp < DelegateClass(Songkick::OAuth2::Model::Client)
    API_CLIENT_APP_NAME = 'API Client App'

    def self.new(*args)
      Songkick::OAuth2::Model::Client.new(*args)
    end

    @@delegate_class=Songkick::OAuth2::Model::Client
    def self.delegate_class_method(names)
      names.each do |name|
        define_method(name) do |*args|
          @@delegate_class.__send__(name, *args)
        end
      end
    end
    delegate_class_method @@delegate_class.singleton_methods

    class << self
      def api_client
        where(name: API_CLIENT_APP_NAME).first
      end

      def create_api_client
        create!(name: API_CLIENT_APP_NAME, redirect_uri: 'http://cli-only.example.com.nonexisting')
      end

      def method_missing(name, *args)
        Songkick::OAuth2::Model::Client.send(name, *args)
      end
    end
  end
end
