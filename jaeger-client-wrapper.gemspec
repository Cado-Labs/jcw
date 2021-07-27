# frozen_string_literal: true

require_relative 'lib/jaeger_client_wrapper/version'

Gem::Specification.new do |spec|
  spec.name          = 'jaeger-client-wrapper'
  spec.version       = JaegerClientWrapper::VERSION
  spec.authors       = ['aleksandr.sta']
  spec.email         = ['aleksandr.sta@okwork.io']

  spec.summary       = 'Wrapper for jaeger-client'
  spec.description   = ''
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.require_paths = ['lib']
  spec.add_development_dependency 'bundler', '>= 2.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_dependency 'activesupport', '>= 5.0'
  spec.add_dependency 'jaeger-client', '~> 1.1.0'
  spec.add_dependency 'railties', '>= 5.0'
  spec.add_dependency 'zeitwerk', '~> 2.4.2'
end
