# frozen_string_literal: false

require_relative "helper"

class TestCSVFilter < Test::Unit::TestCase
  def setup
    @csv = <<-CSV
aaa,bbb,ccc
ddd,eee,fff
    CSV
  end

  # Return stdout and stderr from CLI execution.
  def run_csv_filter(csv, *options)
    top_dir = File.join(__dir__, "..", "..")
    csv_filter = File.join(top_dir, "bin", "csv-filter")
    if File.exist?(csv_filter)
      # In-place test
      command_line = [
        Gem.ruby,
        "-I",
        File.join(top_dir, "lib"),
        csv_filter,
        *options,
      ]
    else
      # Gem test
      command_line = [
        Gem.ruby,
        "-S",
        "csv-filter",
        *options,
      ]
    end
    Tempfile.create("stdout", mode: File::RDWR) do |stdout|
      Tempfile.create("stderr", mode: File::RDWR) do |stderr|
        Tempfile.create(["csv-filter", ".csv"]) do |input|
          input.write(csv)
          input.close
          system(*command_line, in: input.path, out: stdout, err: stderr)
          stdout.rewind
          stderr.rewind
          [stdout.read, stderr.read]
        end
      end
    end
  end

  # Test for invalid option.
  def test_invalid_option
    output, error = run_csv_filter("", "-Z")
    assert_equal(["", "invalid option: -Z\n"],
                 [output, error.lines.first])
  end

  # Test for no options.
  def test_no_options
    assert_equal([@csv, ""],
                 run_csv_filter(@csv))
  end

  # Tests for general options.

  def test_option_h
    output, error = run_csv_filter("", "-h")
    assert_equal(["Usage: csv-filter [options]\n", ""],
                 [output.lines.first, error])
  end

  def test_option_v
    assert_equal(["csv-filter #{CSV::VERSION}\n", ""],
                 run_csv_filter("", "-v"))
  end

  def test_option_input_col_sep
    csv = "aaa:bbb:ccc\nddd:eee:fff\n"
    assert_equal(["aaa,bbb,ccc\nddd,eee,fff\n", ""],
                 run_csv_filter(csv, "--input-col-sep=:"))
  end

  def test_option_input_quote_char
    input_quote_char = "'"
    csv_text = CSV.generate(quote_char: input_quote_char) do |csv|
      csv << ['foo', 0]
      csv << ["'bar'", 1]
      csv << ['"baz"', 2]
    end
    expected = <<-EXPECTED
foo,0
'bar',1
"""baz""",2
    EXPECTED
    assert_equal([expected, ""], run_csv_filter(csv_text, "--input-quote-char=#{input_quote_char}"))
  end

  def test_option_input_row_sep
    csv = "aaa,bbb,ccc:ddd,eee,fff:"
    assert_equal(["aaa,bbb,ccc\nddd,eee,fff\n", ""],
                 run_csv_filter(csv, "--input-row-sep=:"))
  end

  def test_option_output_col_sep
    csv = "aaa,bbb,ccc\nddd,eee,fff\n"
    assert_equal(["aaa:bbb:ccc\nddd:eee:fff\n", ""],
                 run_csv_filter(csv, "--output-col-sep=:"))
  end

  def test_option_output_quote_char
    output_quote_char = "'"
    csv = "foo,0\n'bar',1\n\"baz\",2\n"
    assert_equal(["foo,0\n'''bar''',1\nbaz,2\n", ""],
                 run_csv_filter(csv, "--output-quote_char=#{output_quote_char}"))
  end

  def test_option_output_row_sep
    csv = "aaa,bbb,ccc\nddd,eee,fff\n"
    assert_equal(["aaa,bbb,ccc:ddd,eee,fff:", ""],
                 run_csv_filter(csv, "--output-row-sep=:"))
  end

  def test_option_row_sep
    csv = "aaa,bbb,ccc:ddd,eee,fff:"
    assert_equal(["aaa,bbb,ccc:ddd,eee,fff:", ""],
                 run_csv_filter(csv, "--row-sep=:"))
    assert_equal(["aaa,bbb,ccc.ddd,eee,fff.", ""],
                 run_csv_filter(csv, "--row-sep=.", "--input-row-sep=:"))
    assert_equal(["aaa,bbb,ccc.ddd,eee,fff.", ""],
                 run_csv_filter(csv, "--row-sep=:", "--output-row-sep=."))
  end

  def test_option_col_sep
    csv = "aaa:bbb:ccc\nddd:eee:fff\n"
    assert_equal(["aaa:bbb:ccc\nddd:eee:fff\n", ""],
                 run_csv_filter(csv, "--col-sep=:"))
    assert_equal(["aaa.bbb.ccc\nddd.eee.fff\n", ""],
                 run_csv_filter(csv, "--col-sep=.", "--input-col-sep=:"))
    assert_equal(["aaa.bbb.ccc\nddd.eee.fff\n", ""],
                 run_csv_filter(csv, "--col-sep=:", "--output-col-sep=."))
  end
end
