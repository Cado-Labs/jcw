# frozen_string_literal: true

module JCW
  module Interceptors
    module Gruf
      class Server < ::Gruf::Interceptors::ServerInterceptor
        # rubocop:disable Metrics/MethodLength
        def call
          method = request.method_name

          if Wrapper.config.grpc_ignore_methods.include?(method)
            OpenTelemetry::Common::Utilities.untraced do
              return yield
            end
          end

          tracer = OpenTelemetry.tracer_provider.tracer("gruf")
          service_class = request.service
          method_name = request.method_key
          name = method_name.to_s.camelize
          route = "/#{service_class.service_name}/#{name}"

          attributes = {
            "component" => "gRPC",
            "span.kind" => "server",
            "grpc.method_type" => "request_response",
          }

          extracted_context = OpenTelemetry.propagation.extract(request.active_call.metadata)
          OpenTelemetry::Context.with_current(extracted_context) do
            tracer.in_span(route, attributes: attributes) do |request_span|
              request_span.add_event(
                "request",
                attributes: {
                  "data" => JSON.dump(request.message.to_h),
                }
              )
              yield
            end
          end
        end
      end
    end
  end
end
