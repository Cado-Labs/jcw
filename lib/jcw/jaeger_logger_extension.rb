# frozen_string_literal: true

# :nocov:
module JCW
  module JaegerLoggerExtension
    def add(*args, &block)
      super(*args, &block)

      JaegerLogger.current.add(*args)
    end
  end
end
# :nocov:
