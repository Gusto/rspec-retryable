# frozen_string_literal: true

require "rspec/retryable"
require 'rspec/core/sandbox'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after { RSpec::Retryable.handlers.reset! }

  # Sandboxing: https://github.com/rspec/rspec-core/blob/main/spec/support/sandboxing.rb
  config.around do |ex|
    RSpec::Core::Sandbox.sandboxed do |config|
      # If there is an example-within-an-example, we want to make sure the inner example
      # does not get a reference to the outer example (the real spec) if it calls
      # something like `pending`
      config.before(:context) { RSpec.current_example = nil }

      config.color_mode = :off

      orig_load_path = $LOAD_PATH.dup
      ex.run
      $LOAD_PATH.replace(orig_load_path)
    end
  end
end

RSpec::Retryable.bind
