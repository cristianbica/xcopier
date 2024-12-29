# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

module Xcopier
  class Actor
    class UnknownMessageError < StandardError; end

    attr_reader :copier
    attr_accessor :__queue, :thread, :parent, :result

    delegate :logger, to: :copier
    delegate :log, :info, :debug, :error, to: :logger, allow_nil: true

    def self.spawn!(*args)
      actor = new(*args)
      actor.__queue = Thread::Queue.new
      actor.thread = Thread.new do
        Thread.current[:xcopier_actor] = actor
        actor.__work__
      end
      actor.thread.name = name.demodulize.underscore
      actor.thread.report_on_exception = false
      actor
    end

    def initialize(copier)
      @copier = copier
      super()
    end

    def wait
      thread.value
    end

    def __work__
      while (message = __queue.pop)
        begin
          return result if message == :__terminate

          on_message(message)
        rescue Exception => e # rubocop:disable Lint/RescueException
          on_error(e)
        end
      end
    end

    def tell(message)
      __queue.push(message)
    end

    def on_message(message)
      raise NotImplementedError
    end

    def terminate!
      debug "#{self.class.name.demodulize}: terminating"
      __queue.clear
      __queue.push(:__terminate)
    end

    def on_error(error); end
  end
end
