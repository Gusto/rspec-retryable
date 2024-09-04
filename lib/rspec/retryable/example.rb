# frozen_string_literal: true

require 'rspec/retryable/metadata'
require 'rspec/retryable/payload'

module RSpec
  module Retryable
    module Example
      def finish(reporter)
        metadata[:retryable] ||= Metadata.new

        if @exception
          state = :failed
          execution_result.exception = @exception
          record_finished :failed, reporter
        elsif execution_result.pending_message
          state = :pending
          record_finished :pending, reporter
        else
          state = :passed
          record_finished :passed, reporter
        end

        @payload = RSpec::Retryable::Payload.new(self, state)

        RSpec::Retryable.handlers.invoke(@payload)

        if @payload.retry
          # Replaced the final result by the retry result
          @payload.result = retry_example
        end

        # Notify reporter only if it's not handled by the handlers
        notify_reporter if @payload.notify

        @payload.result
      end

      # https://github.com/rspec/rspec-core/blob/3-10-maintenance/lib/rspec/core/example.rb#L433-L441
      # Used internally to set an exception and fail without actually executing
      # the example when an exception is raised in before(:context).
      def fail_with_exception(...)
        @failed_in_context = true
        super
      end

      def failed_in_context?
        !!@failed_in_context
      end

      def retry_example
        metadata[:retryable].failures << @exception
        metadata[:retryable].attempts += 1
        # Every retry turns off the retry and notify flag, it's up to the handler to turn them back on or not.
        @payload.retry = false
        @payload.notify = false
        # Duplicate the example for re-run
        new_example = duplicate_with(metadata)
        new_example.instance_variable_set(:@id, id)
        # Taken from https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/example_group.rb#L644-L646
        instance = new_example.example_group.new(new_example.inspect_output)
        new_example.example_group.set_ivars(instance, new_example.example_group.before_context_ivars)
        # Use same reporter from example instead of the one passing in to behave like
        # a fresh new example.

        result = new_example.run(instance, reporter)
        # Update the execution result status to the new state from retry
        execution_result.status = new_example.execution_result.status

        if execution_result.status == :failed
          # Sets exception when retry failed
          execution_result.exception = new_example.execution_result.exception
        end

        result
      end

      def notify_reporter
        case @payload.state
        when :failed
          reporter.example_failed self
        when :pending
          reporter.example_pending self
        when :passed
          reporter.example_passed self
        end
      end
    end
  end
end
