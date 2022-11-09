# frozen_string_literal: true

require_relative "config"

module JCW
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

require_relative "init"
require_relative "subscriber"

begin
  require "gruf"

  require_relative "interceptors/gruf/client"
  require_relative "interceptors/gruf/server"
rescue LoadError
end
