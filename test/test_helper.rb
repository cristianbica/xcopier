# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "../test/dummy/config/environment"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "xcopier"

require "support/databases"
require "support/logging"

require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

ApplicationRecord.establish_connection(:test)
