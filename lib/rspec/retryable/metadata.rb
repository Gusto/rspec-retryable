# frozen_string_literal: true

module RSpec
  module Retryable
    class Metadata
      attr_writer :attempts, :retry, :failures

      def attempts
        @attempts ||= 0
      end

      def retry
        return @retry if defined?(@retry)

        @retry = false
      end

      def failures
        @failures ||= []
      end

      def to_h
        {
          attempts: attempts,
          retry: @retry,
          failures: failures,
        }
      end
    end
  end
end
