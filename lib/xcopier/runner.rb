# frozen_string_literal: true

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
      runner.tell(:run)
      ret = runner.wait
      raise ret if ret.is_a?(Exception)

      ret
    end

    def initialize(copier)
      @source_queue = Queue.new
      @destination_queue = Queue.new
      @reader = Reader.spawn!(source_queue, copier).tap { |actor| actor.parent = self }
      @transformer = Transformer.spawn!(source_queue, destination_queue, copier).tap { |actor| actor.parent = self }
      @writer = Writer.spawn!(destination_queue, copier).tap { |actor| actor.parent = self }
      @index = -1
      super
    end

    def on_message(message)
      case message
      in :run
        debug "Runner#message: type=run"
        process
      in :done
        process
      in [:error, e]
        debug "Runner#message: type=error error=#{e.message}"
        finish(e)
      else
        debug "Runner#message: type=unknown message=#{message.inspect}"
        raise UnknownMessageError, "Unknown message: #{message.inspect}"
      end
    end

    def on_error(error)
      debug "Runner#error: #{error.message}"
      finish(error)
    end

    def process
      self.index += 1
      if current_operation.nil?
        finish(true)
      else
        reader.tell([:read, current_operation])
        transformer.tell([:transform, current_operation])
        writer.tell([:write, current_operation])
      end
    end

    def finish(message = nil)
      debug "Runner#finish: message=#{message.inspect}"
      self.result = message

      source_queue.push(:done)
      destination_queue.push(:done)

      reader.terminate!
      transformer.terminate!
      writer.terminate!
      terminate!
    end

    def current_operation
      copier.operations[index]
    end
  end
end
