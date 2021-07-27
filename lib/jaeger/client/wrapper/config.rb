# frozen_string_literal: true

module Jaeger
  module Client
    module Wrapper
      class Config
        attr_writer :enabled,
                    :service_name,
                    :orm,
                    :subscribe_to,
                    :host,
                    :port,
                    :patch_http_client,
                    :http_client

        def enabled
          @enabled ||= false
        end

        alias enabled? enabled

        def service_name
          @service_name ||= defined?(Rails) ? Rails.application.class.name.split('::').first : 'Service'
        end

        def orm
          @orm ||= :sequel
        end

        def subscribe_to
          @subscribe_to ||= []
        end

        def host
          @host ||= '127.0.0.1'
        end

        def port
          @port ||= 6831
        end
      end
    end
  end
end
