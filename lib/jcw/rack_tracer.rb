# frozen_string_literal: true

# inspired https://github.com/opentracing-contrib/ruby-rack-tracer/blob/master/lib/rack/tracer.rb
module JCW
  module Rack
    class Tracer
      REQUEST_URI = "REQUEST_URI"
      REQUEST_PATH = "REQUEST_PATH"
      REQUEST_METHOD = "REQUEST_METHOD"

      # Create a new Rack Tracer middleware.
      #
      # @param app The Rack application/middlewares stack.
      # @param tracer [OpenTracing::Tracer] A tracer to be used when start_span, and extract
      #        is called.
      # @param on_start_span [Proc, nil] A callback evaluated after a new span is created.
      # @param on_finish_span [Proc, nil] A callback evaluated after a span is finished.
      # @param ignore_paths [Array<Class>] An array of paths to be skiped by the tracer.
      # @param errors [Array<Class>] An array of error classes to be captured by the tracer
      #        as errors. Errors are **not** muted by the middleware, they're re-raised afterwards.
      def initialize(app, # rubocop:disable Metrics/ParameterLists
                     tracer: OpenTracing.global_tracer,
                     on_start_span: nil,
                     on_finish_span: nil,
                     trust_incoming_span: true,
                     ignore_paths: Wrapper.config.rack_ignore_paths,
                     errors: [StandardError])
        @app = app
        @tracer = tracer
        @on_start_span = on_start_span
        @on_finish_span = on_finish_span
        @trust_incoming_span = trust_incoming_span
        @errors = errors
        @ignore_paths = ignore_paths
      end

      def call(env)
        method = env[REQUEST_METHOD]
        path = env[REQUEST_PATH]
        url = env[REQUEST_URI]

        return @app.call(env) if @ignore_paths.include?(path)

        handle_error(@errors) do
          env["uber-trace-id"] = env["HTTP_UBER_TRACE_ID"]
          context = @tracer.extract(OpenTracing::FORMAT_TEXT_MAP, env) if @trust_incoming_span
          @scope = build_scope(method, url, context)
          @span = @scope.span

          perform_on_start_span(env, @span, @on_start_span)

          @app.call(env).tap do |status_code, _headers, _body|
            set_tag(@span, status_code, env)
          end
        end
      end

      private

      def handle_error(errors)
        yield
      rescue *errors => e
        @span.set_tag("error", true)
        @span.log_kv(
          event: "error",
          "error.kind": e.class.to_s,
          "error.object": e,
          message: e.message,
          stack: e.backtrace.join("\n"),
        )
        raise
      ensure
        begin
          @scope.close
        ensure
          perform_on_finish_span
        end
      end

      def build_scope(method, url, context)
        @tracer.start_active_span(
          method,
          child_of: context,
          tags: {
            "component" => "rack",
            "span.kind" => "server",
            "http.method" => method,
            "http.url" => url,
          },
        )
      end

      def perform_on_start_span(env, span, on_start_span)
        on_start_span&.call(span)
        env["rack.span"] = span
      end

      def set_tag(span, status_code, env)
        span.set_tag("http.status_code", status_code)
        route = route_from_env(env)
        span.operation_name = route if route
      end

      def route_from_env(env)
        if (sinatra_route = env["sinatra.route"])
          sinatra_route
        elsif (rails_controller = env["action_controller.instance"])
          method = env[REQUEST_METHOD]
          "#{method} #{rails_controller.controller_name}/#{rails_controller.action_name}"
        elsif (grape_route_args = env["grape.routing_args"] || env["rack.routing_args"])
          grape_route_from_args(grape_route_args)
        end
      end

      def grape_route_from_args(route_args)
        route_info = route_args[:route_info]
        if route_info.respond_to?(:path)
          route_info.path
        elsif (rack_route_options = route_info.instance_variable_get(:@options))
          rack_route_options[:path]
        end
      end

      def perform_on_finish_span
        return unless @on_finish_span
        @on_finish_span.call(@span)
      end
    end
  end
end
