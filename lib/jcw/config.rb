# frozen_string_literal: true

module JCW
  class Config
    attr_writer :enabled,
                :service_name,
                :subscribe_to,
                :connection,
                :flush_interval,
                :tags,
                :grpc_ignore_methods,
                :rack_ignore_paths

    def enabled
      @enabled ||= false
    end

    alias enabled? enabled

    def service_name
      @service_name ||= "JCW service"
    end

    def subscribe_to
      @subscribe_to ||= []
    end

    def connection
      @connection ||= { protocol: :udp, host: "127.0.0.1", port: 6831 }
    end

    def flush_interval
      @flush_interval ||= 10
    end

    def tags
      @tags ||= {}
    end

    def grpc_ignore_methods
      @grpc_ignore_methods ||= []
    end

    def rack_ignore_paths
      @rack_ignore_paths ||= []
    end
  end
end
