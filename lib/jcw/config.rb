# frozen_string_literal: true

module JCW
  class Config
    attr_writer :subscribe_to,
                :grpc_ignore_methods

    def subscribe_to
      @subscribe_to ||= []
    end

    def grpc_ignore_methods
      @grpc_ignore_methods ||= []
    end
  end
end
