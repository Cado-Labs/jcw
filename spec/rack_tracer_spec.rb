# frozen_string_literal: true

require "timeout"

class RouteInfo
  attr_accessor :options
end

RSpec.describe JCW::Rack::Tracer do
  let(:tracer) { OpenTracingTestTracer.build }
  let(:on_start_span) { spy }
  let(:on_finish_span) { spy }

  let(:ok_response) { [200, { "Content-Type" => "application/json" }, ['{"ok": true}']] }

  let(:env) do
    Rack::MockRequest.env_for("/test/this/route", method: method)
  end

  let(:method) { "POST" }

  shared_examples "calls on_start_span and on_finish_span callbacks" do
    it "calls on_start_span callback" do
      respond_with { ok_response }
      span = tracer.spans.last
      expect(on_start_span).to have_received(:call).with(span)
    end

    it "calls on_finish_span callback" do
      respond_with { ok_response }
      span = tracer.spans.last
      expect(on_finish_span).to have_received(:call).with(span)
    end

    context "when on_start_span and on_finish_span are empty" do
      let(:on_start_span) { nil }
      let(:on_finish_span) { nil }

      it do
        respond_with { ok_response }
      end
    end

    context "when env has sinatra route set" do
      let(:route) { "POST /users/:id" }

      before { env["sinatra.route"] = route }

      it "adds the route to operation name" do
        respond_with { ok_response }
        span = tracer.spans.last
        expect(span.operation_name).to eq(route)
      end
    end

    context "when env has action_controller.instance set" do
      let(:route) { "POST users/create" }

      before do
        env["action_controller.instance"] = double("UsersController",
                                                   controller_name: "users",
                                                   action_name: "create")
      end

      it "adds the controller/action to operation name" do
        respond_with { ok_response }
        span = tracer.spans.last
        expect(span.operation_name).to eq(route)
      end
    end

    context "when env has grape routing args set" do
      let(:route) { "POST /users/:id" }

      before do
        env["grape.routing_args"] = { route_info: double(path: "/users/:id") }
      end

      it "adds the route path to operation name" do
        respond_with { ok_response }
        span = tracer.spans.last
        expect(span.operation_name).to eq(route)
      end
    end

    context "when env has grape rack routing args set" do
      let(:route) { "POST /users/:id" }
      let(:route_info) { RouteInfo.new }

      before do
        route_info.options = { path: "/users/:id" }
        env["rack.routing_args"] = { route_info: route_info }
      end

      it "adds the route path to operation name" do
        respond_with { ok_response }
        span = tracer.spans.last
        expect(span.operation_name).to eq(route)
      end

      context "when route_info.options is nil" do
        let(:route) { "POST " }

        before do
          route_info.options = nil
          env["rack.routing_args"] = { route_info: route_info }
        end

        it "adds the route path to operation name" do
          respond_with { ok_response }
          span = tracer.spans.last
          expect(span.operation_name).to eq(route)
        end
      end
    end
  end

  context "when path in ignore path list" do
    let(:ignore_path_patterns) { [] }

    before do
      env["REQUEST_PATH"] = "/api/test"
      allow(JCW::Wrapper.config)
        .to receive(:rack_ignore_path_patterns).and_return(ignore_path_patterns)
    end

    context "when path passed" do
      let(:ignore_path_patterns) { ["/api/foo", %r{/bar}] }

      it "create new trace" do
        respond_with { ok_response }

        expect(tracer.spans.count).to eq(1)
      end
    end

    context "when ignore path is string" do
      let(:ignore_path_patterns) { %w[/api/test] }

      it "skip creating new trace" do
        respond_with { ok_response }

        expect(tracer.spans.count).to eq(0)
      end
    end

    context "when ignore path is regexp" do
      let(:ignore_path_patterns) { [%r{/api}] }

      it "skip creating new trace" do
        respond_with { ok_response }

        expect(tracer.spans.count).to eq(0)
      end
    end
  end

  context "when a new request" do
    it "starts a new trace" do
      respond_with { ok_response }

      expect(tracer.spans.count).to eq(1)
      span = tracer.spans[0]
      expect(span).to be_finished
    end

    it "passes span to downstream" do
      respond_with do |env|
        span = tracer.spans.last
        expect(env["rack.span"]).to eq(span)
        expect(env["rack.span"].context.parent_id).to eq(nil)
        ok_response
      end
    end

    it "marks the span as active" do
      respond_with do |_env|
        span = tracer.spans.last
        expect(tracer.active_span).to eq(span)
        ok_response
      end
    end

    include_examples "calls on_start_span and on_finish_span callbacks"
  end

  context "when already traced request" do
    let(:parent_span_name) { "parent span" }
    let(:parent_span) { tracer.start_span(parent_span_name) }

    before { inject(parent_span.context, env) }

    it "starts a child trace" do
      respond_with { ok_response }
      parent_span.finish

      expect(parent_span).to be_finished
      span = tracer.spans.last
      expect(span).to be_finished
      expect(span.operation_name).to eq(method)
      expect(span.context.parent_id).to eq(parent_span.context.span_id)
    end

    it "passes span to downstream" do
      respond_with do |env|
        span = tracer.spans.last
        expect(env["rack.span"]).to eq(span)
        expect(env["rack.span"].context.parent_id).to eq(parent_span.context.span_id)
        ok_response
      end
    end

    it "marks the span as active" do
      respond_with do |_env|
        span = tracer.spans.last
        expect(tracer.active_span).to eq(span)
        ok_response
      end
    end

    include_examples "calls on_start_span and on_finish_span callbacks"
  end

  context "when already traced but untrusted request" do
    it "starts a new trace" do
      respond_with(trust_incoming_span: false) { ok_response }

      expect(tracer.spans.count).to eq(1)
      span = tracer.spans[0]
      expect(span).to be_finished
      expect(span.context.parent_id).to eq(nil)
    end

    it "does not pass incoming span to downstream" do
      respond_with(trust_incoming_span: false) do |env|
        span = tracer.spans.last
        expect(env["rack.span"]).to eq(span)
        expect(env["rack.span"].context.parent_id).to eq(nil)
        ok_response
      end
    end

    include_examples "calls on_start_span and on_finish_span callbacks"
  end

  context "when an exception bubbles-up through the middlewares" do
    it "finishes the span" do
      respond_with_timeout_error = lambda do
        respond_with { |_env| raise Timeout::Error }
      end

      expect(&respond_with_timeout_error).to raise_error do |_|
        span = tracer.spans[0]
        expect(span.operation_name).to eq(method)
        expect(span).to be_finished
      end
    end

    it "marks the span as failed" do
      respond_with_timeout_error = lambda do
        respond_with { |_env| raise Timeout::Error }
      end

      expect(&respond_with_timeout_error).to raise_error do |_|
        span = tracer.spans[0]
        expect(span.operation_name).to eq(method)
        expect(span.tags).to include("error" => true)
      end
    end

    it "logs the error" do
      exception = Timeout::Error.new
      respond_with_timeout_error = lambda do
        respond_with { |_env| raise exception }
      end

      expect(&respond_with_timeout_error).to raise_error do |thrown_exception|
        span = tracer.spans[0]
        expect(span.operation_name).to eq(method)
        expect(span.logs).to include(
          a_hash_including(
            event: "error",
            "error.kind": thrown_exception.class.to_s,
            "error.object": thrown_exception,
            message: thrown_exception.message,
            stack: thrown_exception.backtrace.join("\n"),
          ),
        )
      end
    end

    it "re-raise original exception" do
      expect { respond_with { |_env| raise Timeout::Error } }.to raise_error(Timeout::Error)
    end
  end

  def respond_with(trust_incoming_span: true, &app)
    middleware = described_class.new(
      app,
      tracer: tracer,
      on_start_span: on_start_span,
      on_finish_span: on_finish_span,
      trust_incoming_span: trust_incoming_span,
    )
    middleware.call(env)
  end

  def inject(span_context, env)
    carrier = {}
    tracer.inject(span_context, OpenTracing::FORMAT_TEXT_MAP, carrier)
    carrier.each do |k, v|
      env[k] = v
    end
  end
end
