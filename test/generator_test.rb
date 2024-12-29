# frozen_string_literal: true

require "test_helper"
require "generators/xcopier/copier/copier_generator"

class GeneratorTest < Minitest::Test
  def test_generator
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Xcopier::Generators::CopierGenerator.new(%w[test_full], { quiet: true }).invoke_all
        require "./app/libs/test_full_copier"
        assert_equal [:tenant_ids], TestFullCopier._arguments.pluck(:name)
        assert_equal %i[users companies], TestFullCopier._operations.pluck(:name)
      end
    end
  end
end
