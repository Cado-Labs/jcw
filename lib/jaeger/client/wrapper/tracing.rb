# frozen_string_literal: true

module Jaeger
  module Client
    module Wrapper
      module Tracing
        def self.register_subscribers(subscribers)
          @subscribers = subscribers
        end

        def self.subscribers
          @subscribers
        end

        def self.subscribe_tracing_events
          return if @subscribed

          subscribers.each(&:subscribe!)

          @subscribed = true
        end

        def self.unsubscribe_tracing_events
          return unless @subscribed

          subscribers.each(&:unsubscribe!)

          @subscribed = false
        end

        def self.current_jaeger_scope
          OpenTracing.scope_manager.active
        end
      end
    end
  end
end
