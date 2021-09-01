# frozen_string_literal: true

module JCW
  class Logger
    LEVELS = {
      ::Logger::UNKNOWN => "unknown",
      ::Logger::FATAL => "fatal",
      ::Logger::ERROR => "error",
      ::Logger::WARN => "warn",
      ::Logger::INFO => "info",
      ::Logger::DEBUG => "debug",
    }.freeze

    class << self
      def current
        Thread.current[:jaeger_logger] ||= new
      end
    end

    def add(level, message, progname)
      message ||= progname
      logs << { level: LEVELS[level], message: message } unless message.to_s.empty?
    end

    def logs
      @logs ||= []
    end

    def clear
      @logs = []
    end
  end
end
