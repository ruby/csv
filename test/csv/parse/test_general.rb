# -*- coding: utf-8 -*-
# frozen_string_literal: false

require "timeout"

require_relative "../helper"

#
# Following tests are my interpretation of the
# {CSV RCF}[https://www.ietf.org/rfc/rfc4180.txt].  I only deviate from that
# document in one place (intentionally) and that is to make the default row
# separator <tt>$/</tt>.
#
class TestCSVParseGeneral < Test::Unit::TestCase
  extend DifferentOFS

  BIG_DATA = "123456789\n" * 512

  def test_mastering_regex_example
    ex = %Q{Ten Thousand,10000, 2710 ,,"10,000","It's ""10 Grand"", baby",10K}
    assert_equal( [ "Ten Thousand", "10000", " 2710 ", nil, "10,000",
                    "It's \"10 Grand\", baby", "10K" ],
                  CSV.parse_line(ex) )
  end

  # Old Ruby 1.8 CSV library tests.
  def test_std_lib_csv
    [ ["\t", ["\t"]],
      ["foo,\"\"\"\"\"\",baz", ["foo", "\"\"", "baz"]],
      ["foo,\"\"\"bar\"\"\",baz", ["foo", "\"bar\"", "baz"]],
      ["\"\"\"\n\",\"\"\"\n\"", ["\"\n", "\"\n"]],
      ["foo,\"\r\n\",baz", ["foo", "\r\n", "baz"]],
      ["\"\"", [""]],
      ["foo,\"\"\"\",baz", ["foo", "\"", "baz"]],
      ["foo,\"\r.\n\",baz", ["foo", "\r.\n", "baz"]],
      ["foo,\"\r\",baz", ["foo", "\r", "baz"]],
      ["foo,\"\",baz", ["foo", "", "baz"]],
      ["\",\"", [","]],
      ["foo", ["foo"]],
      [",,", [nil, nil, nil]],
      [",", [nil, nil]],
      ["foo,\"\n\",baz", ["foo", "\n", "baz"]],
      ["foo,,baz", ["foo", nil, "baz"]],
      ["\"\"\"\r\",\"\"\"\r\"", ["\"\r", "\"\r"]],
      ["\",\",\",\"", [",", ","]],
      ["foo,bar,", ["foo", "bar", nil]],
      [",foo,bar", [nil, "foo", "bar"]],
      ["foo,bar", ["foo", "bar"]],
      [";", [";"]],
      ["\t,\t", ["\t", "\t"]],
      ["foo,\"\r\n\r\",baz", ["foo", "\r\n\r", "baz"]],
      ["foo,\"\r\n\n\",baz", ["foo", "\r\n\n", "baz"]],
      ["foo,\"foo,bar\",baz", ["foo", "foo,bar", "baz"]],
      [";,;", [";", ";"]] ].each do |csv_test|
      assert_equal(csv_test.last, CSV.parse_line(csv_test.first))
    end

    [ ["foo,\"\"\"\"\"\",baz", ["foo", "\"\"", "baz"]],
      ["foo,\"\"\"bar\"\"\",baz", ["foo", "\"bar\"", "baz"]],
      ["foo,\"\r\n\",baz", ["foo", "\r\n", "baz"]],
      ["\"\"", [""]],
      ["foo,\"\"\"\",baz", ["foo", "\"", "baz"]],
      ["foo,\"\r.\n\",baz", ["foo", "\r.\n", "baz"]],
      ["foo,\"\r\",baz", ["foo", "\r", "baz"]],
      ["foo,\"\",baz", ["foo", "", "baz"]],
      ["foo", ["foo"]],
      [",,", [nil, nil, nil]],
      [",", [nil, nil]],
      ["foo,\"\n\",baz", ["foo", "\n", "baz"]],
      ["foo,,baz", ["foo", nil, "baz"]],
      ["foo,bar", ["foo", "bar"]],
      ["foo,\"\r\n\n\",baz", ["foo", "\r\n\n", "baz"]],
      ["foo,\"foo,bar\",baz", ["foo", "foo,bar", "baz"]] ].each do |csv_test|
      assert_equal(csv_test.last, CSV.parse_line(csv_test.first))
    end
  end

  # From: [ruby-core:6496]
  def test_aras_edge_cases
    [ [%Q{a,b},               ["a", "b"]],
      [%Q{a,"""b"""},         ["a", "\"b\""]],
      [%Q{a,"""b"},           ["a", "\"b"]],
      [%Q{a,"b"""},           ["a", "b\""]],
      [%Q{a,"\nb"""},         ["a", "\nb\""]],
      [%Q{a,"""\nb"},         ["a", "\"\nb"]],
      [%Q{a,"""\nb\n"""},     ["a", "\"\nb\n\""]],
      [%Q{a,"""\nb\n""",\nc}, ["a", "\"\nb\n\"", nil]],
      [%Q{a,,,},              ["a", nil, nil, nil]],
      [%Q{,},                 [nil, nil]],
      [%Q{"",""},             ["", ""]],
      [%Q{""""},              ["\""]],
      [%Q{"""",""},           ["\"",""]],
      [%Q{,""},               [nil,""]],
      [%Q{,"\r"},             [nil,"\r"]],
      [%Q{"\r\n,"},           ["\r\n,"]],
      [%Q{"\r\n,",},          ["\r\n,", nil]] ].each do |edge_case|
        assert_equal(edge_case.last, CSV.parse_line(edge_case.first))
      end
  end

  def test_james_edge_cases
    # A read at eof? should return nil.
    assert_equal(nil, CSV.parse_line(""))
    #
    # With Ruby 1.8 CSV it's impossible to tell an empty line from a line
    # containing a single +nil+ field.  The old CSV library returns
    # <tt>[nil]</tt> in these cases, but <tt>Array.new</tt> makes more sense to
    # me.
    #
    assert_equal(Array.new, CSV.parse_line("\n1,2,3\n"))
  end

  def test_rob_edge_cases
    [ [%Q{"a\nb"},                         ["a\nb"]],
      [%Q{"\n\n\n"},                       ["\n\n\n"]],
      [%Q{a,"b\n\nc"},                     ['a', "b\n\nc"]],
      [%Q{,"\r\n"},                        [nil,"\r\n"]],
      [%Q{,"\r\n."},                       [nil,"\r\n."]],
      [%Q{"a\na","one newline"},           ["a\na", 'one newline']],
      [%Q{"a\n\na","two newlines"},        ["a\n\na", 'two newlines']],
      [%Q{"a\r\na","one CRLF"},            ["a\r\na", 'one CRLF']],
      [%Q{"a\r\n\r\na","two CRLFs"},       ["a\r\n\r\na", 'two CRLFs']],
      [%Q{with blank,"start\n\nfinish"\n}, ['with blank', "start\n\nfinish"]],
    ].each do |edge_case|
      assert_equal(edge_case.last, CSV.parse_line(edge_case.first))
    end
  end

  def test_non_regex_edge_cases
    # An early version of the non-regex parser fails this test
    [ [ "foo,\"foo,bar,baz,foo\",\"foo\"",
        ["foo", "foo,bar,baz,foo", "foo"] ] ].each do |edge_case|
      assert_equal(edge_case.last, CSV.parse_line(edge_case.first))
    end

    assert_raise(CSV::MalformedCSVError) do
      CSV.parse_line("1,\"23\"4\"5\", 6")
    end
  end

  def test_unquoted_cr_with_lf_row_separator
    data = "field1,field\rwith\rcr,field3\nrow2,data,here\n"
    expected = [
      ["field1", "field\rwith\rcr", "field3"],
      ["row2", "data", "here"]
    ]
    assert_equal(expected, CSV.parse(data, row_sep: "\n"))
  end

  def test_unquoted_cr_with_custom_row_separator
    data = "field1,field\rwith\rcr,field3|row2,data,here|"
    expected = [
      ["field1", "field\rwith\rcr", "field3"],
      ["row2", "data", "here"]
    ]
    assert_equal(expected, CSV.parse(data, row_sep: "|"))
  end

  def test_unquoted_cr_with_crlf_row_separator
    data = "field1,field\r2,field3\r\nrow2,data,here\r\n"
    error = assert_raise(CSV::MalformedCSVError) do
      CSV.parse(data, row_sep: "\r\n")
    end
    assert_equal("Unquoted fields do not allow new line <\"\\r\"> in line 1.",
                 error.message)
  end

  def test_quoted_cr_with_custom_row_separator
    data = "field1,\"field\rwith\rcr\",field3|row2,data,here|"
    expected = [
      ["field1", "field\rwith\rcr", "field3"],
      ["row2", "data", "here"]
    ]
    assert_equal(expected, CSV.parse(data, row_sep: "|"))
  end

  def test_unquoted_cr_in_middle_line
    csv = "line,1,abc\nline,2,\"def\nghi\"\nline,4,some\rjunk\nline,5,jkl\n"
    result = CSV.parse(csv)
    expected = [
      ["line", "1", "abc"],
      ["line", "2", "def\nghi"],
      ["line", "4", "some\rjunk"],
      ["line", "5", "jkl"]
    ]
    assert_equal(expected, result)
  end

  def test_empty_rows_with_cr
    result = CSV.parse("\n" + "\r")
    assert_equal([[], ["\r"]], result)
  end

  def test_malformed_csv_unclosed_quote
    error = assert_raise(CSV::MalformedCSVError) do
      CSV.parse_line('1,2,"3...')
    end
    assert_equal("Unclosed quoted field in line 1.",
                 error.message)
  end

  def test_malformed_csv_illegal_quote_middle_line
    csv = <<-CSV
line,1,abc
line,2,"def\nghi"

line,4,8'10"
line,5,jkl
    CSV

    error = assert_raise(CSV::MalformedCSVError) do
      CSV.parse(csv)
    end
    assert_equal("Illegal quoting in line 4.",
                 error.message)
  end

  def test_the_parse_fails_fast_when_it_can_for_unquoted_fields
    assert_parse_errors_out('valid,fields,bad start"' + BIG_DATA)
  end

  def test_the_parse_fails_fast_when_it_can_for_unescaped_quotes
    assert_parse_errors_out('valid,fields,"bad start"unescaped' + BIG_DATA)
  end

  def test_field_size_limit_controls_lookahead
    assert_parse_errors_out( 'valid,fields,"' + BIG_DATA + '"',
                             field_size_limit: 2048 )
  end

  def test_field_size_limit_max_allowed
    column = "abcde"
    assert_equal([[column]],
                 CSV.parse("\"#{column}\"",
                           field_size_limit: column.size + 1))
  end

  def test_field_size_limit_quote_simple
    column = "abcde"
    assert_parse_errors_out("\"#{column}\"",
                            field_size_limit: column.size)
  end

  def test_field_size_limit_no_quote_implicitly
    column = "abcde"
    assert_parse_errors_out("#{column}",
                            field_size_limit: column.size)
  end

  def test_field_size_limit_no_quote_explicitly
    column = "abcde"
    assert_parse_errors_out("#{column}",
                            field_size_limit: column.size,
                            quote_char: nil)
  end

  def test_field_size_limit_in_extended_column_not_exceeding
    data = <<~DATA
      "a","b"
      "
      2
      ",""
    DATA
    assert_nothing_raised(CSV::MalformedCSVError) do
      CSV.parse(data, field_size_limit: 4)
    end
  end

  def test_field_size_limit_in_extended_column_exceeding
    data = <<~DATA
      "a","b"
      "
      2345
      ",""
    DATA
    assert_parse_errors_out(data, field_size_limit: 5)
  end

  def test_max_field_size_controls_lookahead
    assert_parse_errors_out( 'valid,fields,"' + BIG_DATA + '"',
                             max_field_size: 2048 )
  end

  def test_max_field_size_max_allowed
    column = "abcde"
    assert_equal([[column]],
                 CSV.parse("\"#{column}\"",
                           max_field_size: column.size))
  end

  def test_max_field_size_quote_simple
    column = "abcde"
    assert_parse_errors_out("\"#{column}\"",
                            max_field_size: column.size - 1)
  end

  def test_max_field_size_no_quote_implicitly
    column = "abcde"
    assert_parse_errors_out("#{column}",
                            max_field_size: column.size - 1)
  end

  def test_max_field_size_no_quote_explicitly
    column = "abcde"
    assert_parse_errors_out("#{column}",
                            max_field_size: column.size - 1,
                            quote_char: nil)
  end

  def test_max_field_size_in_extended_column_not_exceeding
    data = <<~DATA
      "a","b"
      "
      2
      ",""
    DATA
    assert_nothing_raised(CSV::MalformedCSVError) do
      CSV.parse(data, max_field_size: 3)
    end
  end

  def test_max_field_size_in_extended_column_exceeding
    data = <<~DATA
      "a","b"
      "
      2345
      ",""
    DATA
    assert_parse_errors_out(data, max_field_size: 4)
  end

  def test_row_sep_auto_cr
    assert_equal([["a"]], CSV.parse("a\r"))
  end

  def test_row_sep_auto_lf
    assert_equal([["a"]], CSV.parse("a\n"))
  end

  def test_row_sep_auto_cr_lf
    assert_equal([["a"]], CSV.parse("a\r\n"))
  end

  def test_seeked_string_io
    input_with_bom = StringIO.new("\ufeffあ,い,う\r\na,b,c\r\n")
    input_with_bom.read(3)
    assert_equal([
                   ["あ", "い", "う"],
                   ["a", "b", "c"],
                 ],
                 CSV.new(input_with_bom).each.to_a)
  end

  def test_quoted_col_sep_and_empty_line
    assert_equal([["one,"], [], ["three"]],
                 CSV.parse(<<-CSV))
"one,"

"three"
                 CSV
  end

  private

  {
    "YJIT"=>1,              # for --yjit-call-threshold=1
    "MJIT"=>5, "RJIT"=>5,   # for --jit-wait
  }.any? do |jit, timeout|
    if (RubyVM.const_defined?(jit) and
        jit = RubyVM.const_get(jit) and
        jit.respond_to?(:enabled?) and
        jit.enabled?)
      PARSE_ERROR_TIMEOUT = timeout
    end
  end
  PARSE_ERROR_TIMEOUT ||= 0.2

  def assert_parse_errors_out(data, timeout: PARSE_ERROR_TIMEOUT, **options)
    assert_raise(CSV::MalformedCSVError) do
      Timeout.timeout(timeout) do
        CSV.parse(data, **options)
        fail("Parse didn't error out")
      end
    end
  end
end
