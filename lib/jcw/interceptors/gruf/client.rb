# frozen_string_literal: true

module JCW
  module Interceptors
    module Gruf
      class Client < ::Gruf::Interceptors::ClientInterceptor
        def call(request_context:)
          tracer = OpenTelemetry.tracer_provider.tracer("gruf")
          metadata = request_context.metadata

          attributes = {
            "component" => "gRPC",
            "span.kind" => "client",
            "grpc.method_type" => "request_response",
            "grpc.headers" => JSON.dump(metadata),
          }

          tracer.in_span(request_context.method.to_s, attributes: attributes) do |span|
            OpenTelemetry.propagation.inject(metadata)

            span.add_event(
              "request",
              attributes: {
                "data" => JSON.dump(request_context.requests.map(&:to_h)),
              },
            )
            yield
          end
        end
      end
    end
  end
end
