# frozen_string_literal: true

require_relative "actor"

module Xcopier
  class Writer < Actor
    attr_reader :queue, :operation

    def initialize(queue, *rest)
      @queue = queue
      super(*rest)
    end

    def on_message(message)
      case message
      in [:write, Operation => operation]
        debug "Writer#message: type=write operation=#{operation.inspect}"
        process(operation)
      else
        debug "Writer#message: type=unknown message=#{message.inspect}"
        raise UnknownMessageError, "Unknown message: #{message.inspect}"
      end
    end

    def on_error(error)
      debug "Writer#error: #{error.message}"
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
        chunk = queue.pop
        if chunk == :done
          @operation = nil
          parent.tell(:done)
          break
        end
        write(chunk)
      end
    end

    def write(records)
      ApplicationRecord.connected_to(shard: :xcopier, role: :writing) do
        operation.model.insert_all(records)
      end
    end

    def setup(operation)
      @operation = operation
    end

    def teardown
      @operation = nil
    end
  end
end
