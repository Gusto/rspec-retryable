# frozen_string_literal: true

require 'rspec/retryable/version'
require 'rspec/retryable/example'
require 'rspec/retryable/handlers'

module RSpec
  module Retryable
    class << self
      def handlers
        @handlers ||= Handlers.new
      end

      def bind
        require 'rspec/core'

        ::RSpec::Core::Example.prepend(RSpec::Retryable::Example)
      end
    end
  end
end
