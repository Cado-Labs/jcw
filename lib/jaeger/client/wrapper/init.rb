# frozen_string_literal: true

module Jaeger
  module Client
    module Wrapper
      class Init
        class << self
          def call
            init_jaeger_client
            set_rack_tracer_middleware
            activate_subscribers
            init_http_tracer
            init_sequel
            init_active_record
          end

          private

          def init_jaeger_client
            return unless config.enabled?

            reporter = config.connection[:protocol] == :tcp ? tcp_reporter : nil

            OpenTracing.global_tracer = Jaeger::Client.build(
              service_name: config.service_name,
              host: config.connection[:host],
              port: config.connection[:port],
              flush_interval: config.flush_interval,
              reporter: reporter,
              tags: config.tags,
            )
          end

          def tcp_reporter
            Jaeger::Reporters::RemoteReporter.new(
              sender: Jaeger::HttpSender.new(
                url: config.connection[:url],
                headers: config.connection[:headers],
                encoder: Jaeger::Encoders::ThriftEncoder.new(
                  service_name: config.service_name,
                  tags: config.tags,
                ),
              ),
              flush_interval: config.flush_interval,
            )
          end

          def set_rack_tracer_middleware
            raise "Rails not found" unless Object.const_defined?("Rails")

            Rails.application.middleware.use(Rack::Tracer)
          end

          def activate_subscribers
            subscribers = config.subscribe_to
            return if subscribers.blank?

            Tracing.register_subscribers(subscribers)
            Tracing.subscribe_tracing_events
          end

          def init_http_tracer
            HTTP::Tracer.instrument
            HTTP::Tracer.remove # remove after gem 'httprb-opentracing' released PR#8
            HttpTracer.patch_perform # remove after gem 'httprb-opentracing' released PR#8
          end

          def init_sequel
            return unless config.trace_sql_request?
            return unless config.orm == :sequel

            Sequel::OpenTracing.instrument
          end

          def init_active_record
            return unless config.trace_sql_request?
            return unless config.orm == :active_record

            ActiveRecord::OpenTracing.instrument
          end

          def config
            Wrapper.config
          end
        end
      end
    end
  end
end
