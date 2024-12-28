# frozen_string_literal: true

module LoggingMixin
  extend ActiveSupport::Concern

  def before_setup
    Rails.logger.debug("-" * 80)
    Rails.logger.debug "#{self.class.name}##{name} [#{Time.new}]"
    Rails.logger.debug("-" * 80)
    @start_time = Time.now.to_i
    super
  end

  def after_teardown
    super
    @end_time = Time.now.to_i
    Rails.logger.debug("-" * 80)
    Rails.logger.debug "#{self.class.name}##{name} finished in #{@end_time - @start_time} seconds [#{Time.new}]"
    Rails.logger.debug("-" * 80)
  end
end

Minitest::Test.prepend(LoggingMixin)
