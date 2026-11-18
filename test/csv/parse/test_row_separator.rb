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

  def test_multiple_characters_part_in_unquoted_value
    data = %Q{a|b,"say ""hi"""|\n|c,"x\ny"|\n}
    with_chunk_size("1") do
      assert_equal([["a|b", "say \"hi\""], ["|c", "x\ny"]],
                   CSV.parse(data, row_sep: "|\n"))
    end
  end

  def test_multiple_characters_part_in_unquoted_value_not_first
    assert_equal([["\"", "c<d"], ["\"", "c>d"]],
                 CSV.parse(%Q{"""",c<d<>"""",c>d<>}, row_sep: "<>"))
  end
end
