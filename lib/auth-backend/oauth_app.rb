require 'delegate'

module Auth::Backend
  class OauthApp < DelegateClass(Songkick::OAuth2::Model::Client)
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
      def method_missing(name, *args)
        Songkick::OAuth2::Model::Client.send(name, *args)
      end
    end
  end
end
