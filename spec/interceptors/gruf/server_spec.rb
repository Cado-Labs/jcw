# frozen_string_literal: true

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

  def initialize(parent: nil)
    @metadata = parent ? { "traceparent" => parent } : {}
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
  before do
    exporter.reset
  end

  let(:exporter) { EXPORTER }
  let(:instrumentation) { OpenTelemetry.tracer_provider.tracer("gruf") }
  let(:span) { exporter.finished_spans.first }
  let(:interceptor) { TestServerInterceptor }

  describe "#call" do
    let(:block) { proc { true } }
    let(:server_call) { interceptor.new(request, Gruf::Error.new) }
    let(:active_call) { RpcTestCall.new }

    let(:request) do
      ::Gruf::Controllers::Request.new(
        method_key: :get_thing,
        service: TestService,
        rpc_desc: :description,
        active_call: active_call,
        message: Google::Protobuf::DescriptorPool.generated_pool
                                                 .lookup("rpc.GetThingResponse").msgclass.new,
      )
    end

    context "without errors" do
      it do
        expect(server_call.call(&block)).to eq("Test Server Call")
        expect(exporter.finished_spans.size).to eq(1)
        expect(span.attributes["component"]).to eq("gRPC")
        expect(span.attributes["span.kind"]).to eq("server")
        expect(span.attributes["grpc.method_type"]).to eq("request_response")
      end
    end

    context "with ignore method" do
      before do
        ::JCW::Wrapper.configure do |config|
          config.grpc_ignore_methods = ["test_service.get_thing"]
        end
      end

      after do
        ::JCW::Wrapper.configure do |config|
          config.grpc_ignore_methods = []
        end
      end

      it do
        expect(server_call.call(&block)).to eq("Test Server Call")
        expect(exporter.finished_spans.size).to eq(0)
      end
    end

    context "with error response" do
      let(:block) { proc { raise "Invalid response" } }

      it do
        expect { server_call.call(&block) }.to raise_error(RuntimeError, "Invalid response")
        expect(exporter.finished_spans.size).to eq(1)
      end
    end

    context "with parent span" do
      before do
        span = instrumentation.start_span("operation-name")
        span.finish
      end

      let(:span) { exporter.finished_spans.last }
      let(:parent_span) { exporter.finished_spans.first }
      let(:parent_span_id) { "00-#{parent_span.hex_trace_id}-#{parent_span.hex_span_id}-01" }
      let(:active_call) { RpcTestCall.new(parent: parent_span_id) }

      it do
        expect(server_call.call(&block)).to eq("Test Server Call")
        expect(exporter.finished_spans.size).to eq(2)
        expect(span.hex_trace_id).to eq(parent_span.hex_trace_id)
      end
    end
  end
end
