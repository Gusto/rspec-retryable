# RSpec::Retryable

RSpec Retryable is a gem that allows you to retry RSpec examples based on custom handlers. This can be useful for handling flaky tests or tests that depend on external systems.

## Installation

Install the gem and add it to the application's Gemfile by executing:

```bash
$ bundle add rspec-retryable
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
$ gem install rspec-retryable
```

## Usage

Simply calling `RSpec::Retryable.bind` enables the ability to retry on test examples. You can add your first handler by using `RSpec::Retryable.handlers.register(SomeHandler)`.

#### Example

Create a file `retry_setup.rb` with the following content:

```retry_setup.rb
require 'rspec/retryable'

class SimpleRetryHandler
  MAX_RETRIES = 2

  def initialize
    # Initialization code here
    @retries = Hash.new(0)
  end

  def call(payload)
    # use payload to set retry or not based on RSpec example state

    if @retries[payload.example.id] < MAX_RETRIES
      # Set `payload.retry` to `true` to enable rspec retry
      payload.retry = true if payload.state == :failed
    else
      # Pass down to next handler
      yield
    end
  end
end

RSpec::Retryable.bind

RSpec::Retryable.handlers.register(SimpleRetryHandler)
```

Then requires the setup in your `spec_helper.rb`

```spec_helper.rb
require 'retry_setup'

RSpec.configure do |config|
  # ... some rspec setup
end
```

`payload` holds below information:

- `example`: (read-only) RSpec example
- `state`: Current state of the example, can be alterted by handlers
- `notify`: default to `true`, if set to `false`, reporter will not be notified
- `result`: this is the final result returned to RSpec runner
- `retry`: default to `false`, if set to `true`, the example will be retried

#### Interact with multiple Handlers

Since we use [Chain-of-responsibility pattern](http://en.wikipedia.org/wiki/Chain-of-responsibility_pattern) to define handlers, it's possible to chain handlers with a payload passing down as `Rack::Builder` or `ActionDispatch::MiddlewareStack` to manage a stack of handlers, for example:

```retry_setup.rb
RSpec::Retryable.bind

class FirstRetryHandler
  def call(payload)
    puts "-> First handler in"

    # ... do something based on payload state ...

    yield

    puts "<- First handler out"
  end
end

# This handler stops retry when expected condition met
class SecondRetryHandler
  def call(payload)
    puts "-> Second handler in"

    # ... do something based on payload state ...

    yield

    puts "<- Second handler out"
  end
end

RSpec::Retryable.handlers.register(FirstRetryHandler)
RSpec::Retryable.handlers.register(SecondRetryHandler)
```

When execute tests, the output will look like:

```
-> First handler in
-> Second handler in
<- Second handler out
<- First handler out
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Gusto/rspec-retryable.
