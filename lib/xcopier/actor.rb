# frozen_string_literal: true

require "concurrent/actor"
require "active_support/core_ext/module/delegation"

module Xcopier
  class Actor < Concurrent::Actor::Context
    attr_reader :copier

    delegate :logger, to: :copier
    delegate :log, :info, :debug, :error, to: :logger, allow_nil: true

    def self.spawn!(*args)
      super(
        name: name.demodulize.underscore.to_sym,
        executor: Concurrent::SingleThreadExecutor.new,
        args: args
      )
    end

    def initialize(copier)
      @copier = copier
      super()
    end
  end
end
