# frozen_string_literal: true

module JCW
  class Init
    class << self
      def call
        init_jaeger_client
        activate_subscribers
        init_http_tracer
      end

      private

      def init_jaeger_client
        return unless config.enabled?

        reporter = config.connection[:protocol].to_sym == :tcp ? tcp_reporter : nil

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
            headers: config.connection[:headers] || {},
            encoder: Jaeger::Encoders::ThriftEncoder.new(
              service_name: config.service_name,
              tags: config.tags,
              logger: config.logger,
            ),
          ),
          flush_interval: config.flush_interval,
        )
      end

      def activate_subscribers
        events = config.subscribe_to
        return if events.blank?

        events.each { |event| JCW::Subscriber.subscribe_to_event!(event) }
      end

      def init_http_tracer
        HTTP::Tracer.instrument
        HTTP::Tracer.remove # remove after gem 'httprb-opentracing' released PR#8
        HttpTracer.patch_perform # remove after gem 'httprb-opentracing' released PR#8
      end

      def config
        Wrapper.config
      end
    end
  end
end
