# frozen_string_literal: true

if ENV["COVER"]
  require "simplecov"
  require "simplecov-lcov"

  SimpleCov::Formatter::LcovFormatter.config do |config|
    config.report_with_single_file = true
    config.lcov_file_name = "lcov.info"
    config.output_directory = "coverage"
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter,
  ])

  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100
    add_filter "spec"
  end
end

require "bundler/setup"
require "jcw"
require "pry"
require "test_rails_app"
require "rack/mock"
require "opentracing_test_tracer"

RSpec.configure do |config|
  Kernel.srand config.seed
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
  config.order = :random
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  Thread.abort_on_exception = true
end
