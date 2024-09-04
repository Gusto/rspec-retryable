# frozen_string_literal: true

RSpec.describe RSpec::Retryable do
  it "has a version number" do
    expect(RSpec::Retryable::VERSION).not_to be nil
  end

  describe ".bind" do
    def capture_target_example(&block)
      reporter = RSpec::Core::Reporter.new(RSpec::Core::Configuration.new)

      target, result = nil, nil

      listener = double("Listener")
      allow(listener).to receive(:example_finished) do |notification|
        target = notification.example
      end

      reporter.register_listener(listener, :example_finished)

      result = RSpec.describe(&block).run(reporter)

      [target, result]
    end

    context "when running example without retry" do
      it "returns proper result" do
        target, result = capture_target_example do
          it { expect(1).to eq(1) }
        end

        expect(target).to be_a(RSpec::Core::Example)
        expect(target.metadata).to have_key(:retryable)
        expect(result).to eq(true)
      end

      context "when failed" do
        it "returns proper result" do
          target, result = capture_target_example do
            it { expect(1).to eq(2) }
          end

          expect(target).to be_a(RSpec::Core::Example)
          expect(target.metadata).to have_key(:retryable)
          expect(target.exception).to be_a(RSpec::Expectations::ExpectationNotMetError)
          expect(result).to eq(false)
        end
      end
    end

    context "when running example with a retry handler" do
      before do
        RSpec::Retryable.handlers.register(Class.new do
          def self.retries=(value)
            @retries = value
          end

          def self.retries
            @retries ||= 0
          end

          def call(payload)
            if self.class.retries.zero?
              payload.retry = true
            end

            self.class.retries += 1
          end
        end)
      end

      it 'runs the test multiple times' do
        target, result = capture_target_example do
          it { expect(1).to eq(2) }
        end

        expect(target.metadata[:retryable].attempts).to eq(1)
        expect(target.execution_result.status).to eq(:failed)
        expect(target.exception).to be_a(RSpec::Expectations::ExpectationNotMetError)
        expect(result).to eq(false)
      end

      context "when retry passed" do
        it "returns proper result" do
          results = [2, 1]

          target, result = capture_target_example do
            it '' do
              expect(1).to eq(results.shift)
            end
          end

          expect(target.metadata[:retryable].attempts).to eq(1)
          expect(target.execution_result.status).to eq(:passed)
          expect(target.exception).to be_nil
          expect(result).to eq(true)
        end
      end
    end
  end
end
