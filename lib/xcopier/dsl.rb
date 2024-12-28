# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/class/attribute"
require "active_support/core_ext/enumerable"
require "xcopier/version"
require_relative "operation"
require_relative "runner"

module Xcopier
  module DSL
    extend ActiveSupport::Concern

    BOOLS = ["1", "yes", "true", true].freeze

    included do
      attr_reader :arguments, :logger

      class_attribute :source, default: nil
      class_attribute :destination, default: :development
      class_attribute :_arguments, instance_accessor: false, instance_predicate: false, default: []
      class_attribute :_operations, instance_accessor: false, instance_predicate: false, default: []
    end

    class_methods do
      def copy(name, **options)
        _operations << { name: name, **options }
      end

      def argument(name, type = :string, **options)
        _arguments << { name: name.to_sym, type: type, **options }
      end
    end

    def initialize(**args)
      validate_arguments(args)
      parse_arguments(args)
    end

    def operations
      @operations ||= self.class._operations.map { |operation| Operation.new(self, **operation) }
    end

    def run
      setup
      Runner.run(self)
    ensure
      teardown
    end

    private

    def setup
      ApplicationRecord.connects_to(
        shards: {
          xcopier: { reading: source, writing: destination }
        }
      )
      @logger = Xcopier.logger
    end

    def teardown
      ApplicationRecord.remove_connection
    end

    def validate_arguments(args)
      given_arguments = args.keys
      expected_arguments = self.class._arguments.pluck(:name)

      missing_arguments = expected_arguments - given_arguments
      raise ArgumentError, "Missing arguments: #{missing_arguments}" if missing_arguments.any?

      unknown_arguments = given_arguments - expected_arguments
      raise ArgumentError, "Unknown arguments: #{unknown_arguments}" if unknown_arguments.any?
    end

    def parse_arguments(args)
      @arguments = self.class._arguments.each_with_object({}) do |definition, hash|
        name = definition[:name]

        if definition[:list]
          values = args[name].split(",").map(&:strip).compact
          hash[name] = values.map { |v| typecast_argument(v, definition) }
        else
          hash[name] = typecast_argument(args[name], definition)
        end
      end
    end

    def typecast_argument(value, definition)
      type = definition[:type]
      return value if type == :string
      return value.to_i if type == :integer
      return Time.parse(value) if type == :time
      return Date.parse(value) if type == :date
      return Xcopier::DSL::BOOLS.include?(value) if type == :boolean

      raise ArgumentError, "Unknown argument type: #{type}"
    end
  end
end
