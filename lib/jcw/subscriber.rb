# frozen_string_literal: true

module JCW
  class Subscriber
    class << self
      def subscribe_to_event!(event_name)
        ActiveSupport::Notifications.subscribe(event_name) do |*args|
          (span = OpenTracing.scope_manager.active&.span) or next
          event = ActiveSupport::Notifications::Event.new(*args)
          span.log_kv(context: span_context(event))
        end
      end

      private

      def span_context(event)
        {
          name: event.name,
          time: event.time,
          payload: event.payload.to_s,
          transaction_id: event.transaction_id,
        }.as_json
      end
    end
  end
end
