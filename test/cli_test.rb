# frozen_string_literal: true

require "test_helper"
require "xcopier/cli"

class CLITest < Minitest::Test
  def setup
    @cli_class = Xcopier::CLI
  end

  def test_parse_with_help_option
    cli = @cli_class.new(["-h"])
    assert_output(/Usage: xcopier copier_name/) do
      refute cli.parse
    end
  end

  def test_parse_with_invalid_copier
    cli = @cli_class.new(["invalid_copier"])
    assert_output(/ERROR: Copier not found/) do
      refute cli.parse
    end
  end

  def test_parse_with_missing_arguments
    cli = @cli_class.new(["full_copier"])
    assert_output(/ERROR: Missing argument values/) do
      refute cli.parse
    end
  end

  def test_parse_with_valid_arguments
    cli = @cli_class.new(["full_copier", "--company-ids=1"])
    assert cli.parse
  end
end
