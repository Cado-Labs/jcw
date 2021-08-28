# frozen_string_literal: true

# :nocov:
module JCW
  class JaegerLogger
    LEVELS = {
      Logger::UNKNOWN => "unknown",
      Logger::FATAL => "fatal",
      Logger::ERROR => "error",
      Logger::WARN => "warn",
      Logger::INFO => "info",
      Logger::DEBUG => "debug",
    }.freeze

    class << self
      def current
        Thread.current[:jaeger_logger] ||= new
      end
    end

    def add(level, message, progname)
      message ||= progname
      logs << { level: LEVELS[level], message: message } if message
    end

    def logs
      @logs ||= []
    end
  end
end
# :nocov:
