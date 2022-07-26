# frozen_string_literal: true

require "rails"

class TestApp < Rails::Application
end

RSpec.describe ::JCW::Logger do
  before do
    Rails.logger = Logger.new(IO::NULL)
    Rails.logger.extend(::JCW::LoggerExtension)
  end

  before do
    messages.each do |log_data|
      Rails.logger.send(log_data[:level], log_data[:message])
    end
  end

  after do
    described_class.current.clear
  end

  context "when send one log with level INFO" do
    let(:messages) do
      [
        { level: "info", message: "Some info message" },
      ]
    end

    it "logs count is 1" do
      expect(described_class.current.logs.count).to eq(1)
    end

    it "logs with one message" do
      expect(described_class.current.logs).to eq(messages)
    end
  end

  context "when send any logs" do
    let(:messages) do
      [
        { level: "info", message: "Some info message" },
        { level: "debug", message: "Some debug message" },
        { level: "error", message: "Some error message" },
      ]
    end

    it "logs count is 3" do
      expect(described_class.current.logs.count).to eq(3)
    end

    it "logs with 3 messages" do
      expect(described_class.current.logs).to eq(messages)
    end
  end

  context "when message is empty" do
    let(:messages) do
      [ { level: "info", message: "" } ]
    end

    it "logs count is 0" do
      expect(described_class.current.logs.count).to eq(0)
    end
  end
end
