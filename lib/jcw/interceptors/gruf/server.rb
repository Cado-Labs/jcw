# frozen_string_literal: true

require "gruf"

module JCW
  module Interceptors
    module Gruf
      class Server < ::Gruf::Interceptors::ServerInterceptor
        # rubocop:disable Metrics/MethodLength
        def call
          method = request.method_name
          return yield if Wrapper.config.grpc_ignore_methods.include?(method)

          tracer = OpenTracing.global_tracer
          on_finish_span = options.fetch(:on_finish_span, nil)
          service_class = request.service
          method_name = request.method_key
          name = method_name.to_s.camelize

          route = "/#{service_class.service_name}/#{name}".to_sym

          begin
            tags = {
              "component" => "gRPC",
              "span.kind" => "server",
              "grpc.method_type" => "request_response",
            }
            hpack_carrier = Hpack.new(request.active_call.metadata)
            parent_span_context = tracer.extract(::OpenTracing::FORMAT_TEXT_MAP, hpack_carrier)
            current_scope = tracer.start_active_span(
              route.to_s,
              child_of: parent_span_context,
              tags: tags,
            )
            current_span = current_scope.span
            current_span.log_kv(event: "request", data: request.message.to_h)

            response = yield

            if response.try(:error_fields)
              current_span.set_tag("error", true)
              current_span.log_kv(event: "error", data: response.to_h)
            end
          rescue => e
            if current_span
              current_span.set_tag("error", true)
              current_span.log_kv(event: "error", error_object: e)
            end
            raise
          ensure
            on_finish_span&.call(current_span)
            current_scope.close if current_span
          end
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
