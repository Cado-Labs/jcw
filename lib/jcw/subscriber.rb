# frozen_string_literal: true

module JCW
  module Subscriber
    extend self

    IGNORED_DATA_TYPES = %i[request response headers exception exception_object].freeze

    def subscribe_to_event!(event)
      ActiveSupport::Notifications.subscribe(event) do |name, started, finished, unique_id, data|
        add(name, started, finished, unique_id, data)
      end
    end

    def add(name, _started, _finished, _unique_id, data)
      # skip Rails internal events
      return if name.start_with?("!")

      span = OpenTracing.scope_manager.active&.span
      return if span.blank?

      if data.is_a?(Hash)
        # we should only mutate the copy of the data
        data = data.dup
        IGNORED_DATA_TYPES.each { |key| data.delete(key) if data.key?(key) } # cleanup data
      end

      span.log_kv(message: name, context: JSON.dump(data))
    end
  end
end
