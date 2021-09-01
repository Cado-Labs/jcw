# frozen_string_literal: true

require "rails"

class TestApp < Rails::Application
end

def make_basic_app
  app = Class.new(TestApp) do
    def self.name
      "RailsTestApp"
    end
  end

  app.config.logger = Logger.new(nil)
  app.config.hosts = nil
  app.config.secret_key_base = "test"
  app.config.eager_load = true
  app.initialize!

  Rails.application = app
  app
end
