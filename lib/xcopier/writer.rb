# frozen_string_literal: true

require_relative "actor"

module Xcopier
  class Writer < Actor
    attr_reader :queue, :operation

    def initialize(queue, *rest)
      @queue = queue
      Thread.current[:xactor] = :writer
      super(*rest)
    end

    def on_message(message)
      case message
      in [:write, Operation => operation]
        debug "Writer#message: type=write operation=#{operation.inspect}"
        process(operation)
        true
      in :stop
        debug "Writer#message: type=stop"
        terminate!
        true
      else
        debug "Writer#message: type=unknown message=#{message.inspect}"
        pass
      end
    end

    def on_event(event)
      debug "Writer#event: #{event.inspect}"
    end

    def process(operation)
      setup(operation)
      work
      teardown
    rescue Exception => e # rubocop:disable Lint/RescueException
      debug "Writer#error: #{e.message}"
      teardown
      parent.tell([:error, e])
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
