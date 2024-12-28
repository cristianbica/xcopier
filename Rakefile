# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

namespace :dummy do
  require_relative "test/dummy/config/application"
  Dummy::Application.load_tasks
end

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[test rubocop]
