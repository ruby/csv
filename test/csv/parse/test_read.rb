# -*- coding: utf-8 -*-
# frozen_string_literal: false

require_relative "../helper"

class TestCSVParseRead < Test::Unit::TestCase
  extend DifferentOFS

  def test_shift
    data = <<-CSV
1
2
3
    CSV
    csv = CSV.new(data)
    assert_equal([
                   ["1"],
                   [["2"], ["3"]],
                   nil,
                 ],
                 [
                   csv.shift,
                   csv.read,
                   csv.shift,
                 ])
  end

  def test_shift_keeps
    csv = CSV.new("a,b\n" * 3)
    assert_equal([
                   ["a", "b"],
                   ["a", "b"],
                   0,
                 ],
                 [
                   csv.shift,
                   csv.shift,
                   scanner_keeps(csv).size,
                 ])
  end

  def test_shift_keeps_after_malformed
    csv = CSV.new("a,b\nabcde,b\n", max_field_size: 4)
    assert_equal(["a", "b"], csv.shift)
    assert_raise(CSV::MalformedCSVError) do
      csv.shift
    end
    assert_equal(0, scanner_keeps(csv).size)
  end

  private
  def scanner_keeps(csv)
    parser = csv.instance_variable_get(:@parser)
    scanner = parser.instance_variable_get(:@scanner)
    scanner.instance_variable_get(:@keeps)
  end
end
