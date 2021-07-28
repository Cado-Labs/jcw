# frozen_string_literal: true

require_relative "wrapper/config"

module Jaeger
  module Client
    module Wrapper
      class << self
        def config
          @config ||= Config.new
        end

        def configure
          yield config
          Init.call
        end
      end
    end
  end
end

require_relative "wrapper/tracing"
require_relative "wrapper/init"
require_relative "wrapper/subscriber"
require_relative "wrapper/http_tracer"
