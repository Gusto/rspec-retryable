# frozen_string_literal: true

module RSpec
  module Retryable
    class Payload
      attr_reader :example
      attr_accessor :notify, :result, :retry, :state

      # Default payload with:
      # - example: RSpec example
      # - state: Current state of the example, can be alterted by handlers
      # - notify: default to `true`, if set to `false`, reporter will not be notified
      # - result: this is the final result returned to RSpec runner
      # - retry: default to `false`, if set to `true`, the example will be retried
      def initialize(example, state)
        @example = example
        @state = state
        @notify = true
        @result = state == :failed ? false : true
        @retry = false
      end
    end
  end
end
