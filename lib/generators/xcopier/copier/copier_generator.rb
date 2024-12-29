# frozen_string_literal: true

require "rails/generators"

module Xcopier
  module Generators
    class CopierGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def create_copier
        template "copiator.rb.tt", File.join("app/libs", class_path, "#{file_name}_copier.rb")
      end

      def models
        Rails.application.eager_load! unless Rails.application.config.eager_load
        ApplicationRecord.subclasses
      end
    end
  end
end
