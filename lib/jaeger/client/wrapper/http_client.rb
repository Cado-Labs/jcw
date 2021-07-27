# frozen_string_literal: true

module Jaeger
  module Client
    module Wrapper
      module HttpClient
        HANDLERS = [
          lambda do |request|
            OpenTracing.start_active_span(Wrapper.config.http_client.to_s) do |scope|
              span = scope.span
              span.log_kv(http_request: request.as_json)
              OpenTracing.inject(span.context, OpenTracing::FORMAT_RACK, request.send(:http_request))
            end
            request
          end
        ].freeze

        def request(*args, **kwargs)
          HANDLERS.each_with_object(super) { |handler, request| handler.call(request) }
        end

        def perform(*args, **kwargs)
          req = request(*args, **kwargs)
          req.perform
        end

        def perform!(*args, **kwargs)
          req = request(*args, **kwargs)
          req.perform!
        end
      end
    end
  end
end
