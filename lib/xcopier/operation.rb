# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"

module Xcopier
  class Operation
    attr_reader :name, :model, :scope, :chunk_size, :overrides, :anonymize

    def initialize(copier, name:, model: nil, scope: nil, chunk_size: 500, overrides: {}, anonymize: {}) # rubocop:disable Metrics/ParameterLists
      @name = name
      @model = model
      @scope = scope
      @chunk_size = chunk_size
      @overrides = overrides.is_a?(Hash) ? overrides.with_indifferent_access : overrides
      @anonymize = anonymize.is_a?(Hash) ? anonymize.with_indifferent_access : anonymize
      prepare_model_and_scope(copier)
    end

    def inspect
      "#<#{self.class.name} name: #{name}, model: #{model.name}, chunk_size: #{chunk_size}, overrides: #{overrides.inspect}, anonymize: #{anonymize.inspect}>"
    end

    private

    def prepare_model_and_scope(copier)
      @model = name.to_s.classify.constantize if model.nil?
      @scope = copier.instance_exec(&scope) if scope.is_a?(Proc)
      @scope = model.all if scope.nil?
    end
  end
end
