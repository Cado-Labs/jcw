# frozen_string_literal: true

require "rails"

class TestApp < Rails::Application
end

def make_basic_app
  Rails.logger = Logger.new(IO::NULL)
end
