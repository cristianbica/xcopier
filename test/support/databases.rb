# frozen_string_literal: true

module DatabasesMixin
  extend ActiveSupport::Concern

  def prepare_databases(*dbs)
    quite do
      dbs.each do |url_or_name|
        config = ApplicationRecord.configurations.find_db_config(url_or_name)
        config ||= ActiveRecord::DatabaseConfigurations::UrlConfig.new("test", "primary", url_or_name)
        ActiveRecord::Tasks::DatabaseTasks.drop(config)
        ActiveRecord::Tasks::DatabaseTasks.create(config)
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Tasks::DatabaseTasks.load_schema(config)
        ApplicationRecord.remove_connection

        @prepared_databases << config
      end
    end
  end

  def before_setup
    @prepared_databases = []
    super
  end

  def after_teardown
    quite do
      @prepared_databases&.each do |config|
        ActiveRecord::Tasks::DatabaseTasks.drop(config)
      rescue StandardError
        nil
      end
    end
    super
  end

  private

  def quite
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end
end

Minitest::Test.prepend(DatabasesMixin)
