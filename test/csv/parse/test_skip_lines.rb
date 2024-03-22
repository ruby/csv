# frozen_string_literal: false

require_relative "../helper"

class TestCSVParseSkipLines < Test::Unit::TestCase
  extend DifferentOFS
  include CSVHelper

  def test_default
    csv = CSV.new("a,b,c\n")
    assert_nil(csv.skip_lines)
  end

  def parse(data, **options)
    # We use Tempfile here to use CSV::Parser::InputsScanner.
    Tempfile.open(["csv-", ".csv"]) do |file|
      file.print(data)
      file.close
      CSV.open(file, **options) do |csv|
        csv.read
      end
    end
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
                 parse(csv, :skip_lines => /\A\s*#/))
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
                 parse(csv, :skip_lines => /\A\s*#/))
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
                 parse(csv, :skip_lines => "."))
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

  def test_matchable
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
                 parse(csv, :skip_lines => Matchable.new(/\A#/)))
  end

  def test_multibyte_data
    # U+3042 HIRAGANA LETTER A
    # U+3044 HIRAGANA LETTER I
    # U+3046 HIRAGANA LETTER U
    value = "\u3042\u3044\u3046"
    with_chunk_size("5") do
      assert_equal([[value], [value]],
                   parse("#{value}\n#{value}\n",
                         :skip_lines => /\A#/))
    end
  end

  def test_empty_line_and_liberal_parsing
    assert_equal([["a", "b"]],
                 parse("a,b\n",
                       :liberal_parsing => true,
                       :skip_lines => /^$/))
  end

  def test_crlf
    assert_equal([["a", "b"]],
                 parse("a,b\r\n,\r\n",
                       :skip_lines => /^,+$/))
  end

  def test_crlf_strip_no_last_crlf
    assert_equal([["a"], ["b"]],
                 parse("a\r\nb",
                       row_sep: "\r\n",
                       skip_lines: /^ *$/,
                       strip: true))
  end

  def test_crlf_quoted_lf
    assert_equal([["\n", ""]],
                 parse("\"\n\",\"\"\r\n",
                       row_sep: "\r\n",
                       skip_lines: /not matched/))
  end
end
