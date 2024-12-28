# frozen_string_literal: true

module DatabasesMixin
  extend ActiveSupport::Concern

  def prepare_databases(*dbs)
    quite do
      dbs.each do |url_or_name|
        puts "Preparing database: #{url_or_name}"
        config = ApplicationRecord.configurations.find_db_config(url_or_name)
        config ||= ActiveRecord::DatabaseConfigurations::UrlConfig.new("test", "primary", url_or_name)
        ActiveRecord::Tasks::DatabaseTasks.drop(config)
        ActiveRecord::Tasks::DatabaseTasks.create(config)
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Tasks::DatabaseTasks.load_schema(config)

        @prepared_databases << config
      end
      ActiveRecord::Base.connection_handler.clear_all_connections!
    end
  end

  def build_database_url(name)
    case ENV.fetch("TEST_DATABASE_ADAPTER", "sqlite3")
    when "sqlite3"
      "sqlite3://tmp/#{name}.sqlite3"
    when "mysql2"
      URI::Generic.build(
        scheme: "mysql2",
        host: ENV.fetch("TEST_DATABASE_HOST", "127.0.0.1"),
        userinfo: [ENV.fetch("TEST_DATABASE_USERNAME", "root"), ENV.fetch("TEST_DATABASE_PASSWORD", "")].join(":"),
        path: "/#{name}"
      ).to_s
    when "postgresql"
      URI::Generic.build(
        scheme: "postgresql",
        host: ENV.fetch("TEST_DATABASE_HOST", "localhost"),
        userinfo: [ENV.fetch("TEST_DATABASE_USERNAME", "postgres"), ENV.fetch("TEST_DATABASE_PASSWORD", "")].join(":"),
        path: "/#{name}"
      ).to_s
    else
      raise "Unsupported database adapter"
    end
  end

  def before_setup
    @prepared_databases = []
    ActiveRecord::Base.connection_handler.clear_all_connections!
    super
  end

  def after_teardown
    quite do
      ActiveRecord::Base.connection_handler.clear_all_connections!
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
