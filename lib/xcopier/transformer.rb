# frozen_string_literal: true

require_relative "actor"
require_relative "anonymizer"

module Xcopier
  class Transformer < Actor
    attr_reader :input, :output, :operation

    def initialize(input, output, *rest)
      @input = input
      @output = output
      super(*rest)
    end

    def on_message(message)
      case message
      in [:transform, Operation => operation]
        debug "Transformer#message: type=transform operation=#{operation.inspect}"
        process(operation)
      else
        debug "Transformer#message: type=unknown message=#{message.inspect}"
        raise UnknownMessageError, "Unknown message: #{message.inspect}"
      end
    end

    def on_error(error)
      debug "Transformer#error: #{error.message}"
      parent.tell([:error, error])
    end

    def process(operation)
      setup(operation)
      work
    ensure
      teardown
    end

    def work
      loop do
        chunk = input.pop

        if chunk == :done
          debug "Transformer: done"
          output.push(:done)
          @operation = nil
          break
        end
        debug "Transformer: transforming #{chunk.size} records"
        transformed = transform(chunk)
        output.push(transformed)
      end
    end

    def transform(chunk)
      chunk.map do |record|
        transform_record(record)
      end
    end

    def transform_record(record)
      record.each_with_object({}) do |(key, value), hash|
        value = apply_overrides(value, key, record)
        value = apply_anonymization(value, key, record)
        hash[key] = value
      end
    end

    def setup(operation)
      @operation = operation
    end

    def teardown
      @operation = nil
    end

    private

    def apply_overrides(value, key, record)
      return value unless operation.overrides.key?(key)

      new_value = operation.overrides[key]
      return new_value unless new_value.respond_to?(:call)

      new_value.call(*[value, record].first(new_value.arity))
    end

    def apply_anonymization(value, key, record)
      return value if operation.overrides.key?(key)
      return Anonymizer.anonymize(key, value) if operation.anonymize == true
      return Anonymizer.anonymize(key, value) if operation.anonymize.is_a?(Array) && operation.anonymize.include?(key)

      value
    end
  end
end
