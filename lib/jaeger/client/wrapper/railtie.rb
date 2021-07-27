# frozen_string_literal: true

module Jaeger
  module Client
    module Wrapper
      class Railtie < ::Rails::Railtie
        initializer 'rack_tracer.use_rack_middleware' do |app|
          next unless jaeger_config.enabled?

          app.config.middleware.use(Rack::Tracer)
        end

        config.after_initialize do
          init_jaeger_client
          activate_tracing
        end

        def init_jaeger_client
          return unless jaeger_config.enabled?

          OpenTracing.global_tracer = Jaeger::Client.build(
            service_name: jaeger_config.service_name,
            host: jaeger_config.host,
            port: jaeger_config.port
          )
        end

        def activate_tracing
          return unless jaeger_config.enabled?

          available_subscribers = {
            action: Tracing::ActionControllerSubscriber,
            orm: Tracing::OrmSubscriber
          }
          subscribers = available_subscribers.slice(*jaeger_config.subscribe_to).values
          return if subscribers.blank?

          Tracing.register_subscribers(subscribers)
          Tracing.subscribe_tracing_events
        end

        def jaeger_config
          Wrapper.config
        end
      end
    end
  end
end
