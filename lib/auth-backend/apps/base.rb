require 'sinatra'
require 'sinatra_warden'
require 'sinatra/flash'
require 'sinatra/activerecord'
require 'kaminari/sinatra'
require 'kaminari/helpers/sinatra_helpers'

module Kaminari::Helpers::SinatraHelpers
  module HelperMethods
    def paginate(scope, options = {}, &block)
      current_path = "#{env['NAMESPACE_INFO']}#{env['PATH_INFO']}" rescue nil
      current_params = Rack::Utils.parse_query(env['QUERY_STRING']).symbolize_keys rescue {}
      paginator = Kaminari::Helpers::Paginator.new(
        ActionViewTemplateProxy.new(:current_params => current_params, :current_path => current_path, :param_name => options[:param_name] || Kaminari.config.param_name),
        options.reverse_merge(:current_page => scope.current_page, :total_pages => scope.total_pages, :per_page => scope.limit_value, :param_name => Kaminari.config.param_name, :remote => false)
      )
      paginator.to_s
    end
  end
end

module Auth::Backend
  module Apps
    module Base
      module Helpers
        include Rack::Utils
        alias_method :h, :escape_html

        def form_field(namespace, id, label, value, options = {})
          options[:namespace] = namespace
          options[:id] = id
          options[:label] = label
          options[:value] = value
          options[:type] ||= 'text'

          erb :'/support/form_field', locals: options
        end

        def warden_data
          session["warden.user.#{env['warden'].config.default_scope}.key"]
        end

        def admin_user
          id = warden_data[:admin_user]
          return unless id
          User.find(id)
        end

        def impersonating?
          warden_data[:admin_user] && warden_data[:admin_user] != warden_data[:user]
        end

        def has_admin_privileges?
          current_user && (current_user.admin? || admin_user)
        end
      end

      def self.registered(app)
        app.register Sinatra::Warden
        app.register Sinatra::Flash
        app.register Sinatra::ActiveRecordExtension

        app.set :views,  File.expand_path('../views', __FILE__)
        app.enable :method_override

        app.helpers Helpers
        app.helpers Kaminari::Helpers::SinatraHelpers
      end
    end
  end
end
