# frozen_string_literal: false

require_relative "../helper"

class TestCSVParseUnquotedCR < Test::Unit::TestCase
  extend DifferentOFS

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
    data = "field1\r,field2,field3\r\nrow2,data,here\r\n"
    assert_raise(CSV::MalformedCSVError) do
      CSV.parse(data, row_sep: "\r\n")
    end
  end

  def test_unquoted_cr_rejected_when_included_in_row_separator
    data = "field1,field\r2,field3\r\nrow2,data,here\r\n"
    assert_raise(CSV::MalformedCSVError) do
      CSV.parse(data, row_sep: "\r\n")
    end
  end

  def test_liberal_parsing_with_custom_row_separator
    data = "field1,field\rwith\rcr,field3|row2,data,here|"
    expected = [
      ["field1", "field\rwith\rcr", "field3"],
      ["row2", "data", "here"]
    ]
    assert_equal(expected, CSV.parse(data, row_sep: "|", liberal_parsing: true))
  end

  def test_quoted_cr_with_custom_row_separator
    data = "field1,\"field\rwith\rcr\",field3|row2,data,here|"
    expected = [
      ["field1", "field\rwith\rcr", "field3"],
      ["row2", "data", "here"]
    ]
    assert_equal(expected, CSV.parse(data, row_sep: "|"))
  end
end 
