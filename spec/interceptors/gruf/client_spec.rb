# frozen_string_literal: true

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
  before do
    exporter.reset
    allow(instrumentation_class).to receive(:tracer).with("gruf").and_return(instrumentation)
  end

  let(:exporter) { EXPORTER }
  let(:instrumentation_class) { OpenTelemetry.tracer_provider }
  let(:instrumentation) { instrumentation_class.tracer("gruf") }
  let(:span) { exporter.finished_spans.first }
  let(:requests) do
    [::Google::Protobuf::DescriptorPool.generated_pool.lookup("rpc.Request").msgclass.new]
  end
  let(:request_context) do
    Gruf::Outbound::RequestContext.new(
      type: :request_response,
      requests: requests,
      call: double(:call, output_metadata: {}),
      method: "/rpc.Request",
      metadata: { foo: "bar" },
    )
  end
  let(:block) { proc { "test" } }
  let(:client_call) { described_class.new.call(request_context: request_context, &block) }

  describe "Client" do
    context "request" do
      it "get response and finish span" do
        expect(client_call).to be_truthy
        expect(exporter.finished_spans.size).to eq(1)
        expect(span.attributes["component"]).to eq("gRPC")
        expect(span.attributes["span.kind"]).to eq("client")
        expect(span.attributes["grpc.method_type"]).to eq("request_response")
      end

      context "raise error" do
        let(:block) { proc { raise StandardError } }

        it "get response and finish span" do
          expect { client_call }.to raise_error(StandardError)
          expect(exporter.finished_spans.size).to eq(1)
          expect(span.attributes["component"]).to eq("gRPC")
          expect(span.attributes["span.kind"]).to eq("client")
          expect(span.attributes["grpc.method_type"]).to eq("request_response")
        end
      end
    end
  end
end
