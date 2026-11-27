# -*- coding: utf-8 -*-
# frozen_string_literal: false

require_relative "../helper"

class TestCSVParseRowSeparator < Test::Unit::TestCase
  extend DifferentOFS
  include CSVHelper

  def test_multiple_characters
    with_chunk_size("1") do
      assert_equal([["a"], ["b"]],
                   CSV.parse("a\r\nb\r\n", row_sep: "\r\n"))
    end
  end

  # :auto detection must ignore CR/LF inside a quoted field.
  def test_auto_quoted_cr
    assert_equal([["a\rb", "x"]],
                 CSV.parse("\"a\rb\",x\n"))
  end

  def test_auto_quoted_cr_lf
    assert_equal([["a\r\nb", "x"]],
                 CSV.parse("\"a\r\nb\",x\n"))
  end

  def test_auto_quoted_cr_only_field
    assert_equal([["\r"]],
                 CSV.parse("\"\r\"\n"))
  end

  # An unquoted CR is still a valid (old Mac) row separator.
  def test_auto_unquoted_cr_still_detected
    assert_equal([["a"], ["b"]],
                 CSV.parse("a\rb\r"))
  end

  # CSV must be able to parse its own generated output.
  def test_auto_round_trip_cr_fields
    rows = [["a\rb", "x"], ["\r", "y"], ["c", "d\r\ne"]]
    generated = CSV.generate {|csv| rows.each {|row| csv << row}}
    assert_equal(rows, CSV.parse(generated))
  end
end
