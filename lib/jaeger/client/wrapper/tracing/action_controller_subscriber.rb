# frozen_string_literal: true

# require 'jaeger/client/wrapper/tracing/abstract_subscriber'

module Jaeger
  module Client
    module Wrapper
      module Tracing
        class ActionControllerSubscriber < AbstractSubscriber
          EVENT_NAME = 'process_action.action_controller'

          def self.subscribe!
            subscribe_to_event(EVENT_NAME)
          end
        end
      end
    end
  end
end
