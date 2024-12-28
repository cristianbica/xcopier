# frozen_string_literal: true

require "test_helper"

class ArgumentsParsingTest < Minitest::Test
  def setup
    @klass = Class.new do
      include Xcopier::DSL
    end
  end

  def test_argument_parsing_string
    @klass.argument :arg1, :string
    @klass.argument :arg2, :string, list: true
    instance = @klass.new(arg1: "test", arg2: "test1 ,test2")

    assert_equal "test", instance.arguments[:arg1]
    assert_equal %w[test1 test2], instance.arguments[:arg2]
  end

  def test_argument_parsing_integer
    @klass.argument :arg1, :integer
    @klass.argument :arg2, :integer, list: true
    instance = @klass.new(arg1: 42, arg2: "1, 2 ,3 , 4,5")

    assert_equal 42, instance.arguments[:arg1]
    assert_equal [1, 2, 3, 4, 5], instance.arguments[:arg2]
  end

  def test_argument_parsing_date
    @klass.argument :arg1, :date
    @klass.argument :arg2, :date, list: true
    instance = @klass.new(arg1: "2023-01-01", arg2: "2023-01-01, 2023-01-02")

    assert_equal Date.new(2023, 1, 1), instance.arguments[:arg1]
    assert_equal [Date.new(2023, 1, 1), Date.new(2023, 1, 2)], instance.arguments[:arg2]
  end

  def test_argument_parsing_time
    @klass.argument :arg1, :time
    @klass.argument :arg2, :time, list: true
    instance = @klass.new(arg1: "2023-01-01 12:00:00", arg2: "2023-01-01 12:00:00, 2023-01-02 13:00:00")

    assert_equal Time.new(2023, 1, 1, 12, 0, 0), instance.arguments[:arg1]
    assert_equal [Time.new(2023, 1, 1, 12, 0, 0), Time.new(2023, 1, 2, 13, 0, 0)], instance.arguments[:arg2]
  end

  def test_argument_parsing_boolean
    @klass.argument :arg1, :boolean
    @klass.argument :arg2, :boolean, list: true
    instance = @klass.new(arg1: true, arg2: "1, yes, true, no, false, nope")

    assert instance.arguments[:arg1]
    assert_equal [true, true, true, false, false, false], instance.arguments[:arg2]
  end
end
