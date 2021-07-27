# frozen_string_literal: true

module Jaeger
  module Client
    module Wrapper
      module_function

      def config
        @config ||= Config.new
      end

      def configure
        yield config
      end
    end
  end
end
