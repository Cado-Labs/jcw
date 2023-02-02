# Project is deprecated


# JCW &middot; <a target="_blank" href="https://github.com/Cado-Labs"><img src="https://github.com/Cado-Labs/cado-labs-logos/raw/main/cado_labs_badge.svg" alt="Supported by Cado Labs" style="max-width: 100%; height: 20px"></a> &middot; [![Coverage Status](https://coveralls.io/repos/github/Cado-Labs/jcw/badge.svg?branch=gem-without-zeitwerk)](https://coveralls.io/github/Cado-Labs/jcw?branch=gem-without-zeitwerk) &middot; [![Gem Version](https://badge.fury.io/rb/jcw.svg)](https://badge.fury.io/rb/jcw)

Helper for the gem "opentelemetry-ruby".

---

<p>
  <a href="https://github.com/Cado-Labs">
    <img src="https://github.com/Cado-Labs/cado-labs-resources/blob/main/cado_labs_supporting_rounded.svg" alt="Supported by Cado Labs" />
  </a>
</p>

---

## Installation

```ruby
gem 'jcw'
```

```shell
bundle install
# --- or ---
gem install jcw
```

```ruby
require 'jcw'
```

## Usage

#### GRPC Integration
Client side

```
# Add JCW::Interceptors::Gruf::Client Interceptor to Gruf Client Initializer
options = {}
client_options = { timeout: 10, interceptors: [JCW::Interceptors::Gruf::Client.new] }

client = Gruf::Client.new(
  service: Test::Service, options: options, client_options: client_options
)

request_method = "some_method"
client.call(request_method)
```

Server side

```ruby
# Add Server Interceptor
Rails.configuration.to_prepare do
  Gruf.configure do |config|
    config.interceptors.use(JCW::Interceptors::Gruf::Server)
  end
end  

# Configure
::JCW::Wrapper.configure do |config|
  config.subscribe_to = [/.*/]
  config.grpc_ignore_methods = %w[grpc.ignore.method]
end
```

#### Example settings Opentelemetry

Add your base gem for Opentelemetry to a Gemfile:

```ruby
gem "opentelemetry-exporter-jaeger"
gem "opentelemetry-sdk"
```

Add specific gems for instrumentations, example:
```ruby
ggem "opentelemetry-instrumentation-pg"
gem "opentelemetry-instrumentation-http"
gem "opentelemetry-instrumentation-rack"
gem "opentelemetry-instrumentation-redis"
gem "opentelemetry-instrumentation-sidekiq"
```

Add to initializer and configure OpenTelemetry::SDK

```ruby
require "opentelemetry/sdk"
require "opentelemetry/exporter/jaeger"
require "opentelemetry/instrumentation/rack"
require "opentelemetry/instrumentation/sidekiq"
require "opentelemetry/instrumentation/redis"
require "opentelemetry/instrumentation/pg"

OpenTelemetry::SDK.configure do |c|
  c.service_name = "PROJECT"
  c.use("OpenTelemetry::Instrumentation::HTTP")
  c.use("OpenTelemetry::Instrumentation::Rack", {
    url_quantization: -> (path, _env) { path.to_s },
    untraced_endpoints: %w[/cable],
  })
  c.use("OpenTelemetry::Instrumentation::Sidekiq", {
    span_naming: :job_class,
    peer_service: "Sidekiq",
  })
  c.use("OpenTelemetry::Instrumentation::Redis", {
    peer_service: "REDIS",
    # The obfuscation of arguments in the db.statement attribute is enabled by default.
    # To include the full query, set db_statement to :include.
    # To obfuscate, set db_statement to :obfuscate.
    # To omit the attribute, set db_statement to :omit.
    db_statement: :include,
    trace_root_spans: false,
  })
  c.use("OpenTelemetry::Instrumentation::PG", {
    # You may optionally set a value for 'peer.service', which
    # will be included on all spans from this instrumentation:
    peer_service: "Postgres",

    # By default, this instrumentation includes the executed SQL as the `db.statement`
    # semantic attribute. Optionally, you may disable the inclusion of this attribute entirely by
    # setting this option to :omit or sanitize the attribute by setting to :obfuscate
    db_statement: :include,
  })
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
      OpenTelemetry::Exporter::Jaeger::AgentExporter.new(
        host: "localhost",
        port: "6831",
      ),
    ),
  )
end
```

For more information on <a href="https://github.com/open-telemetry/opentelemetry-ruby">
OpenTelemetry</a>, visit: https://opentelemetry.io/ 

### Contributing

 - Fork it ( https://github.com/Cado-Labs/jcw )
 - Create your feature branch (`git checkout -b feature/my-new-feature`)
 - Commit your changes (`git commit -am '[feature_context] Add some feature'`)
 - Push to the branch (`git push origin feature/my-new-feature`)
 - Create new Pull Request

## License

Released under MIT License.

## Supporting

<a href="https://github.com/Cado-Labs">
  <img src="https://github.com/Cado-Labs/cado-labs-resources/blob/main/cado_labs_supporting_rounded.svg" alt="Supported by Cado Labs" />
</a>

## Authors

[Aleksandr Starovojtov](https://github.com/AS-AlStar)
