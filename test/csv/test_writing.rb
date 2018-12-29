# -*- coding: utf-8 -*-
# frozen_string_literal: false

require_relative "helper"

class TestCSVWriting < Test::Unit::TestCase
  extend DifferentOFS

  def test_tab
    assert_equal("\t#{$INPUT_RECORD_SEPARATOR}",
                 CSV.generate_line(["\t"]))
  end

  def test_quote_character
    assert_equal(%Q[foo,"""",baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", %Q["], "baz"]))
  end

  def test_quote_character_double
    assert_equal(%Q[foo,"""""",baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", %Q[""], "baz"]))
  end

  def test_quote
    assert_equal(%Q[foo,"""bar""",baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", %Q["bar"], "baz"]))
  end

  def test_quote_lf
    assert_equal(%Q["""\n","""\n"#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([%Q["\n], %Q["\n]]))
  end

  def test_quote_cr
    assert_equal(%Q["""\r","""\r"#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([%Q["\r], %Q["\r]]))
  end

  def test_quote_last
    assert_equal(%Q[foo,"bar"""#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", %Q[bar"]]))
  end

  def test_quote_lf_last
    assert_equal(%Q[foo,"\nbar"""#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", %Q[\nbar"]]))
  end

  def test_quote_lf_value_lf
    assert_equal(%Q[foo,"""\nbar\n"""#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", %Q["\nbar\n"]]))
  end

  def test_quote_lf_value_lf_nil
    assert_equal(%Q[foo,"""\nbar\n""",#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", %Q["\nbar\n"], nil]))
  end

  def test_quote_empty
    assert_equal(%Q["""",""#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([%Q["], ""]))
  end
  def test_empty
    assert_equal(%Q[foo,"",baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", "", "baz"]))
  end

  def test_empty_only
    assert_equal(%Q[""#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([""]))
  end

  def test_empty_double
    assert_equal(%Q["",""#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["", ""]))
  end

  def test_cr
    assert_equal(%Q[foo,"\r",baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", "\r", "baz"]))
  end

  def test_lf
    assert_equal(%Q[foo,"\n",baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", "\n", "baz"]))
  end

  def test_cr_lf
    assert_equal(%Q[foo,"\r\n",baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", "\r\n", "baz"]))
  end

  def test_cr_dot_lf
    assert_equal(%Q[foo,"\r.\n",baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", "\r.\n", "baz"]))
  end

  def test_cr_lf_cr
    assert_equal(%Q[foo,"\r\n\r",baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", "\r\n\r", "baz"]))
  end

  def test_cr_lf_lf
    assert_equal(%Q[foo,"\r\n\n",baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", "\r\n\n", "baz"]))
  end

  def test_cr_lf_comma
    assert_equal(%Q["\r\n,"#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["\r\n,"]))
  end

  def test_cr_lf_comma_nil
    assert_equal(%Q["\r\n,",#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["\r\n,", nil]))
  end

  def test_comma
    assert_equal(%Q[","#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([","]))
  end

  def test_comma_double
    assert_equal(%Q[",",","#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([",", ","]))
  end

  def test_comma_and_value
    assert_equal(%Q[foo,"foo,bar",baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", "foo,bar", "baz"]))
  end

  def test_one_element
    assert_equal(%Q[foo#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo"]))
  end

  def test_nil_values_only
    assert_equal(%Q[,,#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([nil, nil, nil]))
  end

  def test_nil_double_only
    assert_equal(%Q[,#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([nil, nil]))
  end

  def test_nil_values
    assert_equal(%Q[foo,,,#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", nil, nil, nil]))
  end

  def test_nil_value_first
    assert_equal(%Q[,foo,baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([nil, "foo", "baz"]))
  end

  def test_nil_value_middle
    assert_equal(%Q[foo,,baz#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", nil, "baz"]))
  end

  def test_nil_value_last
    assert_equal(%Q[foo,baz,#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", "baz", nil]))
  end

  def test_nil_empty
    assert_equal(%Q[,""#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([nil, ""]))
  end

  def test_nil_cr
    assert_equal(%Q[,"\r"#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([nil, "\r"]))
  end

  def test_values
    assert_equal(%Q[foo,bar#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["foo", "bar"]))
  end

  def test_semi_colon
    assert_equal(%Q[;#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([";"]))
  end

  def test_semi_colon_values
    assert_equal(%Q[;,;#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line([";", ";"]))
  end

  def test_tab_values
    assert_equal(%Q[\t,\t#{$INPUT_RECORD_SEPARATOR}],
                 CSV.generate_line(["\t", "\t"]))
  end

  def test_col_sep
    assert_equal("a;b;;c\n",
                 CSV.generate_line(["a", "b", nil, "c"],
                                   col_sep: ";"))
    assert_equal("a\tb\t\tc\n",
                 CSV.generate_line(["a", "b", nil, "c"],
                                   col_sep: "\t"))
  end

  def test_row_sep
    assert_equal("a,b,,c\r\n",
                 CSV.generate_line(["a", "b", nil, "c"],
                                   row_sep: "\r\n"))
  end

  def test_force_quotes
    assert_equal(%Q{"1","b","","already ""quoted"""\n},
                 CSV.generate_line([1, "b", nil, %Q{already "quoted"}],
                                   force_quotes: true))
  end
end
