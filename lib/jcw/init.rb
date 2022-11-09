# frozen_string_literal: true

module JCW
  class Init
    class << self
      def call
        activate_subscribers
      end

      private

      def activate_subscribers
        events = config.subscribe_to
        return if events.blank?

        events.each { |event| JCW::Subscriber.subscribe_to_event!(event) }
      end

      def config
        Wrapper.config
      end
    end
  end
end
