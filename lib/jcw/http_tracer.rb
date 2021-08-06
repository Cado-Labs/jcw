# frozen_string_literal: true

# Patch unless gem 'httprb-opentracing' not released PR#8
# :nocov:
module JCW
  module HttpTracer
    class << self
      # rubocop:disable Metrics/MethodLength
      def patch_perform
        ::HTTP::Client.class_eval do
          def perform_with_tracing(request, options)
            if ::HTTP::Tracer.ignore_request.call(request, options)
              res = perform_without_tracing(request, options)
            else
              path, host, port, verb = nil
              path = request.uri.path if request.uri.respond_to?(:path)
              host = request.uri.host if request.uri.respond_to?(:host)
              port = request.uri.port if request.uri.respond_to?(:port)
              verb = request.verb.to_s.upcase if request.respond_to?(:verb)

              tags = {
                "component" => "ruby-httprb",
                "span.kind" => "client",
                "http.method" => verb,
                "http.url" => path,
                "peer.host" => host,
                "peer.port" => port,
              }.compact

              tracer = ::HTTP::Tracer.tracer

              tracer.start_active_span("http.request", tags: tags) do |scope|
                request.headers.merge!(options.headers)
                OpenTracing.inject(scope.span.context, OpenTracing::FORMAT_RACK,
                                   request.headers)

                res = perform_without_tracing(request, options)

                scope.span.set_tag("http.status_code", res.status)
                scope.span.set_tag("error", true) if res.is_a?(StandardError)
              end
            end

            res
          end

          alias_method :perform_without_tracing, :perform
          alias_method :perform, :perform_with_tracing
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
# :nocov:
