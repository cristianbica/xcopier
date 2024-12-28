# frozen_string_literal: true

require_relative "actor"

module Xcopier
  class Reader < Actor
    attr_reader :queue, :operation

    def initialize(queue, *rest)
      @queue = queue
      super(*rest)
    end

    def on_message(message)
      case message
      in [:read, Operation => operation]
        debug "Reader#message: type=read operation=#{operation.inspect}"
        process(operation)
      else
        debug "Reader#message: type=unknown message=#{message.inspect}"
        raise UnknownMessageError, "Unknown message: #{message.inspect}"
      end
    end

    def on_error(error)
      debug "Reader#error: #{error.message}"
      parent.tell([:error, error])
    end

    def process(operation)
      setup(operation)
      work
    ensure
      teardown
    end

    def work
      each_chunk do |chunk|
        queue.push(chunk)
      end
      queue.push(:done)
    end

    def each_chunk
      ApplicationRecord.connected_to(shard: :xcopier, role: :reading) do
        operation.scope.in_batches(of: operation.chunk_size) do |relation|
          yield operation.model.connection.exec_query(relation.to_sql).to_a
        end
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
