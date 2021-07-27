# frozen_string_literal: true

module Jaeger
  module Client
    module Wrapper
      module Tracing
        class AbstractSubscriber
          class << self
            def subscribe!
              raise NotImplementedError
            end

            def unsubscribe!
              ActiveSupport::Notifications.unsubscribe(self::EVENT_NAME)
            end

            # rubocop:disable Metrics/MethodLength
            def subscribe_to_event(event_name)
              ActiveSupport::Notifications.subscribe(event_name) do |*args|
                span = OpenTracing.scope_manager.active&.span
                next unless span

                event = ActiveSupport::Notifications::Event.new(*args)
                context = {
                  name: event.name,
                  time: event.time,
                  payload: event.payload.to_s,
                  transaction_id: event.transaction_id
                }
                span&.log_kv(context: context.as_json)
              end
            end
            # rubocop:enable Metrics/MethodLength
          end
        end
      end
    end
  end
end
