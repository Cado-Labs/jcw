# frozen_string_literal: true

require 'rack/tracer'
require 'jaeger/client'
require 'zeitwerk'
require 'active_support'
require 'rails'
loader = Zeitwerk::Loader.for_gem
loader.setup

loader.eager_load
