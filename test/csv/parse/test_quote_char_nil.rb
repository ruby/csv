# -*- coding: utf-8 -*-
# frozen_string_literal: false

require_relative "../helper"

class TestCSVParseQuoteCharNil < Test::Unit::TestCase
  extend DifferentOFS

  def test_general
    assert_equal(["a", "b"], CSV.parse_line(%Q{a,b}, quote_char: nil))
  end

  def test_end_with_nil
    assert_equal(["a", nil, nil, nil], CSV.parse_line(%Q{a,,,}, quote_char: nil))
  end

  def test_nil_nil
    assert_equal([nil, nil], CSV.parse_line(%Q{,}, quote_char: nil))
  end

  def test_unquoted_value_multiple_characters_col_sep
    data = %q{a<b<=>x}
    assert_equal([[%Q{a<b}, "x"]], CSV.parse(data, col_sep: "<=>", quote_char: nil))
  end

  def test_csv_header_string
    # activate headers
    csv = nil
    data = <<~DATA
      first,second,third
      A,B,C
      1,2,3
    DATA

    # first data row - skipping headers
    row = csv[0]
    assert_not_nil(row)
    assert_instance_of(CSV::Row, row)
    assert_equal([%w{my first}, %w{new second}, %w{headers third}], row.to_a)

    # second data row
    row = csv[1]
    assert_not_nil(row)
    assert_instance_of(CSV::Row, row)
    assert_equal([%w{my A}, %w{new B}, %w{headers C}], row.to_a)

    # third data row
    row = csv[2]
    assert_not_nil(row)
    assert_instance_of(CSV::Row, row)
    assert_equal([%w{my 1}, %w{new 2}, %w{headers 3}], row.to_a)

    # empty
    assert_nil(csv[3])
  end

  def test_comma
    assert_equal([["a", "b", nil, "d"]],
                 CSV.parse("a,b,,d", col_sep: ",", quote_char: nil))
  end

  def test_space
    assert_equal([["a", "b", nil, "d"]],
                 CSV.parse("a b  d", col_sep: " ", quote_char: nil))
  end

  def test_multiple_space
    assert_equal([["a b", nil, "d"]],
                 CSV.parse("a b    d", col_sep: "  ", quote_char: nil))
  end

  def test_multiple_characters_leading_empty_fields
    data = <<-CSV
<=><=>A<=>B<=>C
1<=>2<=>3
    CSV
    assert_equal([
                   [nil, nil, "A", "B", "C"],
                   ["1", "2", "3"],
                 ],
                 CSV.parse(data, col_sep: "<=>", quote_char: nil))
  end
end
