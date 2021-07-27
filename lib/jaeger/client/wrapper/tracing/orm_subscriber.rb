# frozen_string_literal: true

module Jaeger
  module Client
    module Wrapper
      module Tracing
        class OrmSubscriber < AbstractSubscriber
          EVENT_NAME = "sql.#{Wrapper.config.orm}"

          def self.subscribe!
            subscribe_to_event(EVENT_NAME)
          end
        end
      end
    end
  end
end
