# frozen_string_literal: true

require "google/protobuf"

class TestServerInterceptor < JCW::Interceptors::Gruf::Server
  def initialize(request, error, options: {})
    super(request, error, options)
  end

  def call
    super

    "Test Server Call"
  end
end

class TestService
  include GRPC::GenericService

  self.service_name = "rpc.TestService"
end

class RpcTestCall
  attr_reader :metadata

  def initialize(metadata_exist: true)
    @metadata = metadata_exist ? { "uber-trace-id" => "1231:3422:23445:3443" } : {}
  end
end

class ErrorResponse
  def error_fields
    { some_error: true }
  end

  def to_h
    self
  end
end

class RescueResponse
  def error_fields
    raise StandardError, "Standard Error"
  end
end

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "rpc.Thing" do
    optional :id, :uint32, 1
    optional :name, :string, 2
  end
  add_message "rpc.GetThingResponse" do
    optional :thing, :message, 1, "rpc.Thing"
  end
end

RSpec.describe JCW::Interceptors::Gruf::Server do
  RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

  def set_jaeger
    ::JCW::Wrapper.configure do |config|
      config.service_name = "ServiceName"
      config.connection = connection
      config.enabled = enabled
      config.subscribe_to = subscribe_to
      config.grpc_ignore_methods = grpc_ignore_methods
    end
  end

  let(:enabled) { true }
  let(:connection) { { protocol: :udp, host: "127.0.0.1", port: 6831 } }
  let(:subscribe_to) { [/.*/] }
  let(:grpc_ignore_methods) { [] }

  let(:interceptor) { TestServerInterceptor }

  describe "#call" do
    let(:block) { proc { true } }
    let(:server_call) { interceptor.new(request, error) }

    let(:request) do
      ::Gruf::Controllers::Request.new(
        method_key: :get_thing,
        service: TestService,
        rpc_desc: :description,
        active_call: RpcTestCall.new,
        message: Google::Protobuf::DescriptorPool.generated_pool
                                                 .lookup("rpc.GetThingResponse").msgclass.new,
      )
    end
    let(:error) { Gruf::Error.new }

    before { set_jaeger }

    context "without errors" do
      it do
        expect(server_call.call(&block)).to eq("Test Server Call")
      end
    end

    context "with ignore method" do
      let(:grpc_ignore_methods) { ["test_service.get_thing"] }

      it do
        expect(server_call.call(&block)).to eq("Test Server Call")
      end
    end

    context "with error response" do
      let(:block) { proc { ErrorResponse.new } }

      it do
        expect(server_call.call(&block)).to eq("Test Server Call")
      end
    end

    context "with rescue response" do
      let(:block) { proc { RescueResponse.new } }

      it do
        expect { server_call.call(&block) }.to raise_error(StandardError)
      end
    end

    context "without current_span" do
      before { allow_any_instance_of(Jaeger::Scope).to receive(:span).and_return(nil) }

      it do
        expect { server_call.call(&block) }.to raise_error(NoMethodError)
      end
    end

    context "with on finish span" do
      let(:server_call) do
        interceptor.new(request, error, options: { on_finish_span: -> (_) { true } })
      end

      it do
        expect(server_call.call(&block)).to eq("Test Server Call")
      end
    end

    context "with on finish span and without current_span" do
      before { allow_any_instance_of(Jaeger::Scope).to receive(:span).and_return(nil) }

      let(:server_call) do
        interceptor.new(request, error, options: { on_finish_span: -> (_) { true } })
      end

      it do
        expect { server_call.call(&block) }.to raise_error(NoMethodError)
      end
    end

    context "without rescue and without current_span" do
      before do
        allow_any_instance_of(Jaeger::Scope).to receive(:span).and_return(nil)
        allow(nil).to receive(:log_kv).and_return(true)
      end

      it do
        expect(server_call.call(&block)).to eq("Test Server Call")
      end
    end
  end
end
