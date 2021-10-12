# frozen_string_literal: true

require "google/protobuf"

class TestServerInterceptor < ::Gruf::Interceptors::ServerInterceptor
  def call
    Math.sqrt(4)
    yield
  end
end

class TestService
  include GRPC::GenericService

  self.service_name = "rpc.TestService"
end

class RpcTestCall
  attr_reader :metadata

  def initialize
    @metadata = { "authorization" => "Basic #{Base64.encode64('grpc:token')}" }
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
  let(:interceptor) { TestServerInterceptor }
  let(:interceptor_args) { {} }
  let(:interceptors) { { interceptor => interceptor_args } }

  describe "#call" do
    block = proc { true }
    subject(:server_call) { interceptor.new(request, error, {}).call(&block) }

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

    it do
      expect(server_call).to be_truthy
    end
  end
end
