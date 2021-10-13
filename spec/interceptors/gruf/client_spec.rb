# frozen_string_literal: true

require "google/protobuf"
require "opentracing"

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "rpc.Request" do
    optional :id, :uint32, 1
    optional :name, :string, 2
  end
  add_message "rpc.Response" do
    optional :thing, :message, 1, "rpc.Request"
  end
end

RSpec.describe JCW::Interceptors::Gruf::Client do
  def set_jaeger
    ::JCW::Wrapper.configure do |config|
      config.service_name = "ServiceName"
      config.connection = connection
      config.enabled = enabled
    end
  end

  let(:enabled) { true }
  let(:connection) { { protocol: :udp, host: "127.0.0.1", port: 6831 } }

  let(:type) { :request_response }
  let(:requests) do
    [::Google::Protobuf::DescriptorPool.generated_pool.lookup("rpc.Request").msgclass]
  end
  let(:call) { double(:call, output_metadata: {}) }
  let(:grpc_method) { "/rpc.Request" }
  let(:metadata) { { foo: "bar" } }

  let(:request_context) do
    Gruf::Outbound::RequestContext.new(
      type: type,
      requests: requests,
      call: call,
      method: grpc_method,
      metadata: metadata,
    )
  end
  let(:block) { proc { "test" } }
  let(:client_call) { described_class.new.call(request_context: request_context, &block) }

  describe "Client" do
    before { set_jaeger }

    context "with metadata" do
      it do
        expect(client_call).to be_truthy
      end
    end

    context "with mock" do
      before { allow(::Jaeger::Injectors).to receive(:context_as_jaeger_string).and_return(nil) }

      it do
        expect(client_call).to be_truthy
      end
    end
  end
end
