# frozen_string_literal: false

require_relative "../helper"

class TestCSVParseSkipLines < Test::Unit::TestCase
  extend DifferentOFS

  def test_default
    csv = CSV.new("a,b,c\n")
    assert_nil(csv.skip_lines)
  end

  def test_regexp
    csv = <<-CSV
1
#2
 #3
4
    CSV
    assert_equal([
                   ["1"],
                   ["4"],
                 ],
                 CSV.parse(csv, :skip_lines => /\A\s*#/))
  end

  def test_regexp_quoted
    csv = <<-CSV
1
#2
"#3"
4
    CSV
    assert_equal([
                   ["1"],
                   ["#3"],
                   ["4"],
                 ],
                 CSV.parse(csv, :skip_lines => /\A\s*#/))
  end

  def test_string
    csv = <<-CSV
1
.2
3.
4
    CSV
    assert_equal([
                   ["1"],
                   ["4"],
                 ],
                 CSV.parse(csv, :skip_lines => "."))
  end

  class RegexStub
  end

  def test_not_matchable
    regex_stub = RegexStub.new
    csv = CSV.new("1\n", :skip_lines => regex_stub)
    error = assert_raise(ArgumentError) do
      csv.shift
    end
    assert_equal(":skip_lines has to respond to #match: #{regex_stub.inspect}",
                 error.message)
  end

  class Matchable
    def initialize(pattern)
      @pattern = pattern
    end

    def match(line)
      @pattern.match(line)
    end
  end

  def test_skip_lines_match
    csv = <<-CSV
1
# 2
3
# 4
    CSV
    assert_equal([
                   ["1"],
                   ["3"],
                 ],
                 CSV.parse(csv, :skip_lines => Matchable.new(/\A#/)))
  end
end