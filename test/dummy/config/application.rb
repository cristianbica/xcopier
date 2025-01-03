# frozen_string_literal: true

require_relative "boot"

# require "rails/all"
#
require "rails"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_view/railtie"
# require "action_mailer/railtie"
# require "active_job/railtie"
# require "action_cable/engine"
# require "action_mailbox/engine"
# require "action_text/engine"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.active_record.maintain_test_schema = false
    config.eager_load = false
  end
end
