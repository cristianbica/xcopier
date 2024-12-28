# frozen_string_literal: true

require_relative "actor"

module Xcopier
  class Reader < Actor
    attr_reader :queue, :operation

    def initialize(queue, *rest)
      @queue = queue
      Thread.current[:xactor] = :reader
      super(*rest)
    end

    def on_message(message)
      case message
      in [:read, Operation => operation]
        debug "Reader#message: type=read operation=#{operation.inspect}"
        process(operation)
      in :stop
        debug "Reader#message: type=stop"
        terminate!
        true
      else
        debug "Reader#message: type=unknown message=#{message.inspect}"
        pass
      end
    end

    def on_event(event)
      debug "Reader#event: #{event.inspect}"
    end

    def process(operation)
      setup(operation)
      read
      teardown
    rescue Exception => e # rubocop:disable Lint/RescueException
      debug "Reader#error: #{e.message}"
      teardown
      parent.tell([:error, e])
    end

    def read
      each_chunk do |chunk|
        queue.push(chunk)
      end
      queue.push(:done)
    end

    def each_chunk
      ApplicationRecord.connected_to(shard: :xcopier, role: :reading) do
        operation.scope.in_batches(of: operation.chunk_size) do |relation|
          yield operation.model.connection.execute(relation.to_sql).to_a
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
