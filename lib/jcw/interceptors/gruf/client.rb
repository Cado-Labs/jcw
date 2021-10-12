# frozen_string_literal: true

require "gruf"

module JCW
  module Interceptors
    module Gruf
      class Client < ::Gruf::Interceptors::ClientInterceptor
        def call(request_context:)
          tracer = OpenTracing.global_tracer
          metadata = request_context.metadata

          tags = {
            "component" => "gRPC",
            "span.kind" => "client",
            "grpc.method_type" => "request_response",
            "grpc.headers" => metadata,
          }

          tracer.start_active_span(request_context.method.to_s, tags: tags) do |current_scope|
            current_span = current_scope.span
            current_span.log_kv(
              event: "request",
              data: request_context.requests.map { |request| request.try(:to_h) },
            )
            current_span.log_kv(event: "metadata", data: metadata)
            hpack_carrier = Hpack.new(metadata)
            tracer.inject(current_span.context, ::OpenTracing::FORMAT_TEXT_MAP, hpack_carrier)

            yield
          end
        end
      end
    end
  end
end
