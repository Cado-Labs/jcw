# frozen_string_literal: true

module JCW
  module LoggerExtension
    def add(*args, &block)
      super(*args, &block)

      Logger.current.add(*args)
    end
  end
end
