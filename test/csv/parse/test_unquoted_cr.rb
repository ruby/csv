# -*- coding: utf-8 -*-
# frozen_string_literal: false

require_relative "../helper"

class TestCSVParseUnquotedCR < Test::Unit::TestCase
  extend DifferentOFS

  def test_accept_cr_in_unquoted_field_when_row_separator_is_lf_only
    # When row separator is just \n, \r should be allowed in unquoted fields
    data = "field1,field\rwith\rcr,field3\nrow2,data,here\n"
    expected = [
      ["field1", "field\rwith\rcr", "field3"],
      ["row2", "data", "here"]
    ]
    assert_equal(expected, CSV.parse(data, row_sep: "\n"))
  end

  def test_accept_cr_in_unquoted_field_when_row_separator_is_custom
    # When row separator is custom (like "|"), \r should be allowed in unquoted fields
    data = "field1,field\rwith\rcr,field3|row2,data,here|"
    expected = [
      ["field1", "field\rwith\rcr", "field3"],
      ["row2", "data", "here"]
    ]
    assert_equal(expected, CSV.parse(data, row_sep: "|"))
  end

  def test_reject_cr_when_row_separator_includes_cr
    # When row separator includes \r (like \r\n), \r should still be rejected in unquoted fields
    data = "field1,field2,field3\r\nrow2,data,here\r\n"
    expected = [
      ["field1", "field2", "field3"],
      ["row2", "data", "here"]
    ]
    assert_equal(expected, CSV.parse(data, row_sep: "\r\n"))
  end

  def test_reject_cr_when_row_separator_is_cr_only
    # When row separator is just \r, \r should be rejected in unquoted fields
    data = "field1,field2,field3\rrow2,data,here\r"
    expected = [
      ["field1", "field2", "field3"],
      ["row2", "data", "here"]
    ]
    assert_equal(expected, CSV.parse(data, row_sep: "\r"))
  end

  def test_liberal_parsing_with_custom_row_separator
    # Test liberal parsing mode with custom row separator
    data = "field1,field\rwith\rcr,field3|row2,data,here|"
    expected = [
      ["field1", "field\rwith\rcr", "field3"],
      ["row2", "data", "here"]
    ]
    assert_equal(expected, CSV.parse(data, row_sep: "|", liberal_parsing: true))
  end

  def test_quoted_fields_with_cr_and_custom_row_separator
    # Quoted fields should always allow \r regardless of row separator
    data = "field1,\"field\rwith\rcr\",field3|row2,data,here|"
    expected = [
      ["field1", "field\rwith\rcr", "field3"],
      ["row2", "data", "here"]
    ]
    assert_equal(expected, CSV.parse(data, row_sep: "|"))
  end
end 
