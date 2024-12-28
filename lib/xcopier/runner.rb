# frozen_string_literal: true

require "concurrent/promise"
require_relative "actor"
require_relative "reader"
require_relative "transformer"
require_relative "writer"

module Xcopier
  class Runner < Actor
    attr_reader :source_queue, :destination_queue, :copier, :reader, :transformer, :writer, :promise
    attr_accessor :index

    def self.run(copier)
      runner = spawn!(copier)
      ret = runner.ask(:run).value.wait!
      raise ret.value if ret.value.is_a?(Exception)

      ret.value
    end

    def initialize(copier)
      @source_queue = Queue.new
      @destination_queue = Queue.new
      @reader = Reader.spawn!(source_queue, copier)
      @transformer = Transformer.spawn!(source_queue, destination_queue, copier)
      @writer = Writer.spawn!(destination_queue, copier)
      @promise = Concurrent::Promise.new
      @index = -1
      Thread.current[:xactor] = :runner
      super
    end

    def on_message(message)
      case message
      in :run
        debug "Runner#message: type=run"
        process
        promise
      in :done
        process
      in [:terminated, reason]
        debug "Runner#message: type=terminated reason=#{reason.inspect}"
      in [:error, e]
        debug "Runner#message: type=error error=#{e.message}"
        finish(e)
      else
        debug "Runner#message: type=unknown message=#{message.inspect}"
        pass
      end
    end

    def on_event(event)
      debug "Runner#event: #{event.inspect}"
    end

    def process
      self.index += 1
      if current_operation.nil?
        finish
      else
        reader.tell([:read, current_operation])
        transformer.tell([:transform, current_operation])
        writer.tell([:write, current_operation])
      end
    end

    def finish(message = nil)
      debug "Runner#finish: message=#{message.inspect}"
      source_queue.push(:done)
      destination_queue.push(:done)
      reader.ask!(:stop)
      reader.executor.shutdown
      transformer.ask!(:stop)
      transformer.executor.shutdown
      writer.ask!(:stop)
      writer.executor.shutdown
      terminate!
      promise.set(message)
    end

    def current_operation
      copier.operations[index]
    end

    def stop
      model.connection_pool.disconnect!
      terminate!
    end
  end
end
