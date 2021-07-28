# frozen_string_literal: true

module Jaeger
  module Client
    module Wrapper
      module Tracing
        class << self
          attr_reader :subscribers

          def register_subscribers(subscribers)
            @subscribers = subscribers
          end

          def subscribe_tracing_events
            subscribers.each { |subscriber| Subscriber.subscribe_to_event!(subscriber) }
          end
        end
      end
    end
  end
end
