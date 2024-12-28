# frozen_string_literal: true

require_relative "actor"
require_relative "anonymizer"

module Xcopier
  class Transformer < Actor
    attr_reader :read_queue, :write_queue, :operation

    def initialize(read_queue, write_queue, *rest)
      @read_queue = read_queue
      @write_queue = write_queue
      Thread.current[:xactor] = :transformer
      super(*rest)
    end

    def on_message(message)
      case message
      in [:transform, Operation => operation]
        debug "Transformer#message: type=transform operation=#{operation.inspect}"
        process(operation)
      in :stop
        debug "Transformer#message: type=stop"
        terminate!
        true
      else
        debug "Transformer#message: type=unknown message=#{message.inspect}"
        pass
      end
    end

    def on_event(event)
      debug "Transformer#event: #{event.inspect}"
    end

    def process(operation)
      @operation = operation
      work
    rescue Exception => e # rubocop:disable Lint/RescueException
      debug "Transformer#error: #{e.message}"
      parent.tell([:error, e])
    end

    def work
      loop do
        chunk = read_queue.pop

        if chunk == :done
          write_queue.push(:done)
          @operation = nil
          break
        end
        write_queue.push(transform(chunk))
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

    private

    def apply_overrides(value, key, record)
      return value unless operation.overrides.key?(key)

      new_value = operation.overrides[key]
      return new_value unless new_value.respond_to?(:call)

      new_value.call(*[value, record].first(new_value.arity))
    end

    def apply_anonymization(value, key, record)
      return Anonymizer.anonymize(key, value) if operation.anonymize == true || operation.anonymize[key] == true

      return value unless operation.anonymize.key?(key)

      new_value = operation.anonymize[key]
      return new_value unless new_value.respond_to?(:call)

      new_value.call(*[value, record].first(new_value.arity))
    end
  end
end
