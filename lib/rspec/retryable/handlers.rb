# frozen_string_literal: true

module RSpec
  module Retryable
    class Handlers
      def initialize
        @handlers = []
      end

      def register(klass, *args, **kwargs)
        @handlers << klass.new(*args, **kwargs)
      end

      def reset!
        @handlers.clear
      end

      def invoke(payload)
        traverse(0, payload)
      end

      private

      def traverse(index, payload)
        @handlers[index]&.call(payload) do
          traverse(index + 1, payload)
        end
      end
    end
  end
end
