require_relative "helper"

class TestTSV < Test::Unit::TestCase
  def test_default_separator
    tsv = CSV::TSV.new(String.new)
    assert_equal("\t", tsv.col_sep)
  end

  def test_override_separator
    tsv = CSV::TSV.new(String.new, col_sep: ",")
    assert_equal(",", tsv.col_sep)
  end

  def test_read_tsv_data
    data = "a\tb\tc\n1\t2\t3"
    result = CSV::TSV.parse(data)
    assert_equal([["a", "b", "c"], ["1", "2", "3"]], result.to_a)
  end

  def test_write_tsv_data
    output = String.new
    CSV::TSV.generate(output) do |tsv|
      tsv << ["a", "b", "c"]
      tsv << ["1", "2", "3"]
    end
    assert_equal("a\tb\tc\n1\t2\t3\n", output)
  end

  def test_inheritance
    assert_kind_of(CSV, CSV::TSV.new(String.new))
  end
end
