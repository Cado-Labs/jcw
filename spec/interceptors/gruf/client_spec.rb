# frozen_string_literal: true

require "google/protobuf"

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
  let(:request_context) do
    Gruf::Outbound::RequestContext.new(
      type: type,
      requests: requests,
      call: call,
      method: grpc_method,
      metadata: metadata,
    )
  end
  let(:type) { :request_response }
  let(:requests) do
    [::Google::Protobuf::DescriptorPool.generated_pool.lookup("rpc.Request").msgclass]
  end
  let(:call) { double(:call, output_metadata: {}) }
  let(:grpc_method) { "/rpc.Request" }
  let(:metadata) { { foo: "bar" } }
  let(:block) { proc { "test" } }

  subject(:client_call) { described_class.new.call(request_context: request_context, &block) }

  it "test" do
    expect(client_call).to be_truthy
  end
end
