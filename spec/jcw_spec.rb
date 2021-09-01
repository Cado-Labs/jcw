# frozen_string_literal: true

RSpec.describe JCW::Wrapper do
  def set_jaeger
    ::JCW::Wrapper.configure do |config|
      config.service_name = "ServiceName"
      config.connection = connection
      config.enabled = enabled
      config.flush_interval = 10
      config.subscribe_to = subscribe_to
      config.tags = {
        hostname: "custom-hostname",
        custom_tag: "custom-tag-value",
      }
    end
  end

  let(:enabled) { true }
  let(:connection) { { protocol: :udp, host: "127.0.0.1", port: 6831 } }
  let(:subscribe_to) { %w[process_action.action_controller start_processing.action_controller] }

  specify "set OpenTracing.global_tracer" do
    set_jaeger
    expect(OpenTracing.global_tracer.class).to eq Jaeger::Tracer
  end

  context "ActiveSupport::Notifications subscribers" do
    context "send fake message to subscribers" do
      let(:start_args) { %w[start_processing.action_controller arg1 arg2 arg3 arg4] }
      let(:procces_args) { %w[process_action.action_controller arg1 arg2 arg3 arg4] }
      let(:start_event) { ActiveSupport::Notifications::Event.new(*start_args) }
      let(:process_event) { ActiveSupport::Notifications::Event.new(*procces_args) }

      before { set_jaeger }

      specify "with span and log created" do
        allow(ActiveSupport::Notifications::Event).to receive(:new).and_return(start_event)
        allow(ActiveSupport::Notifications::Event).to receive(:new).and_return(process_event)

        OpenTracing.start_active_span(self.class.name) do
          ActiveSupport::Notifications.publish(*start_args)
          ActiveSupport::Notifications.publish(*procces_args)
        end
      end

      specify "without span and log not created" do
        expect(ActiveSupport::Notifications::Event).not_to receive(:new)
        expect(ActiveSupport::Notifications::Event).not_to receive(:new)

        ActiveSupport::Notifications.publish(*start_args)
        ActiveSupport::Notifications.publish(*procces_args)
      end
    end

    specify "set subscribers" do
      expect(ActiveSupport::Notifications).to receive(:subscribe)
                                                  .with("process_action.action_controller")
      expect(ActiveSupport::Notifications).to receive(:subscribe)
                                                  .with("start_processing.action_controller")
      set_jaeger
    end

    context "when subscribe_to is blank" do
      let(:subscribe_to) { [] }

      specify "subscribers not set" do
        expect(ActiveSupport::Notifications).not_to receive(:subscribe)
                                                        .with("process_action.action_controller")
        expect(ActiveSupport::Notifications).not_to receive(:subscribe)
                                                        .with("start_processing.action_controller")
        set_jaeger
      end
    end
  end

  context "configure UDP connection" do
    let(:udp_setting) do
      {
        service_name: "ServiceName",
        host: "127.0.0.1",
        port: 6831,
        flush_interval: 10,
        reporter: nil,
        tags: {
          hostname: "custom-hostname",
          custom_tag: "custom-tag-value",
        },
      }
    end

    after do
      set_jaeger
    end

    it "set Jaeger::Client.build" do
      expect(Jaeger::Client).to receive(:build).with(udp_setting)
    end

    it "set HttpTracer" do
      expect(HTTP::Tracer).to receive(:instrument)
    end

    context "when config disabled" do
      let(:enabled) { false }

      it "set Jaeger::Client.build" do
        expect(Jaeger::Client).not_to receive(:build).with(any_args)
      end
    end
  end

  context "when connection TCP" do
    after do
      ::JCW::Wrapper.configure do |config|
        config.service_name = "ServiceName"
        config.connection = {
          protocol: :tcp,
          url: "http://localhost:14268/api/traces",
          headers: {},
        }
        config.enabled = true
        config.flush_interval = 10
        config.subscribe_to =
          %w[process_action.action_controller start_processing.action_controller]
        config.tags = {
          hostname: "custom-hostname",
          custom_tag: "custom-tag-value",
        }
      end
    end

    it "set config" do
      expect(Jaeger::Client).to receive(:build).with(any_args)
      expect(HTTP::Tracer).to receive(:instrument)
    end
  end
end
