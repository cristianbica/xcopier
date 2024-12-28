# frozen_string_literal: true

require_relative "xcopier/version"
require_relative "xcopier/dsl"
require "active_support/core_ext/module/attribute_accessors"
require "logger"

module Xcopier
  mattr_accessor :logger do
    @logger ||= Logger.new($stdout, level: ENV.fetch("LOG_LEVEL", :info))
  end
end
