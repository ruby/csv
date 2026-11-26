require_relative "../helper"

class TestCSVParseByteScanner < Test::Unit::TestCase
  include CSVHelper

  BytePattern = CSV::Parser::BytePattern
  ByteScanner = CSV::Parser::ByteScanner

  def setup
    omit("String#byteindex is required") unless BytePattern::BYTEINDEX_AVAILABLE
  end

  INPUTS = [
    "",
    "abc",
    "a,b,,c",
    "\"a\"\"b\",c\r\nd",
    "\r\n\n\r",
    "  x \t",
    "日本語,\"語\"\n",
    "a" * 40 + "," + "b" * 40,
  ].freeze

  def assert_same_as_regexp(pattern, regexp)
    INPUTS.each do |input|
      input.bytesize.succ.times do |position|
        next unless input.byteslice(0, position).valid_encoding?
        expected = StringScanner.new(input)
        expected.pos = position
        actual = ByteScanner.new(input)
        actual.pos = position
        message = "#{regexp.inspect} at #{position} in #{input.inspect}"
        assert_equal([expected.check(regexp), expected.skip(regexp)],
                     [actual.check(pattern), actual.skip(pattern)],
                     message)
        expected.pos = position
        actual.pos = position
        assert_equal([expected.scan(regexp), expected.pos],
                     [actual.scan(pattern), actual.pos],
                     message)
      end
    end
  end

  def test_literal_byte
    assert_same_as_regexp(BytePattern.literal(","), /,/)
  end

  def test_literal_bytes
    assert_same_as_regexp(BytePattern.literal("\r\n"), /\r\n/)
  end

  def test_alternation
    assert_same_as_regexp(BytePattern.alternation(["\r\n", "\n", "\r"]),
                          /\r\n|\n|\r/)
  end

  def test_run_in_byte
    assert_same_as_regexp(BytePattern.run_in("\""), /"+/)
  end

  def test_run_in_bytes
    assert_same_as_regexp(BytePattern.run_in(" \t"), /[ \t]+/)
  end

  def test_run_except_byte
    assert_same_as_regexp(BytePattern.run_except("\""), /[^"]+/)
  end

  def test_run_except_bytes
    assert_same_as_regexp(BytePattern.run_except(",\"\r\n"), /[^,"\r\n]+/)
  end

  def test_run_except_bytes_moving_back
    pattern = BytePattern.run_except(",\n")
    scanner = ByteScanner.new("ab,cd\nef")
    assert_equal("ab", scanner.scan(pattern))
    scanner.pos = 3
    assert_equal("cd", scanner.scan(pattern))
    scanner.pos = 0
    assert_equal("ab", scanner.scan(pattern))
    scanner.pos = 6
    assert_equal("ef", scanner.scan(pattern))
  end

  def test_run_except_bytes_other_string
    pattern = BytePattern.run_except(",\n")
    assert_equal("abc", ByteScanner.new("abc,d").scan(pattern))
    assert_equal("x", ByteScanner.new("x\nyz").scan(pattern))
  end
end
