# frozen_string_literal: true

module JCW
  module Subscriber
    extend self

    IGNORED_PAYLOAD_KEYS = %i[request response headers exception exception_object].freeze

    def subscribe_to_event!(event)
      ActiveSupport::Notifications.subscribe(event) do |name, start, finish, _uid, payload|
        add(name, payload, finish - start)
      end
    end

    def add(name, payload, duration)
      # skip Rails internal events
      return if name.start_with?("!")

      span = OpenTracing.scope_manager.active&.span
      return if span.blank?

      if payload.is_a?(Hash)
        # we should only mutate the copy of the payload
        payload = payload.dup
        IGNORED_PAYLOAD_KEYS.each { |key| payload.delete(key) if payload.key?(key) }
      end

      span.log_kv(message: name, context: JSON.dump(payload), duration: duration)
    end
  end
end
