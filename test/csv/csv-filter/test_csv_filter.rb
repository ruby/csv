# frozen_string_literal: false

require_relative '../helper'

require 'csv'

class TestFilter < Test::Unit::TestCase

  def setup
    @rows = [
      %w[aaa bbb ccc],
      %w[ddd eee fff],
    ]
  end

  # Return CSV string generated from rows array and options.
  def make_csv_s(rows: Rows, **options)
    CSV.generate(**options) do|csv|
      rows.each do |row|
        csv << row
      end
    end
  end

  # Return filepath of file containing CSV data.
  def csv_filepath(csv_in_s, dirpath, option_sym)
    filename = "#{option_sym}.csv"
    filepath = File.join(dirpath, filename)
    File.write(filepath, csv_in_s)
    filepath
  end

  # Return stdout and stderr from CLI execution.
  def run_csv_filter(filepath, *cli_option_names)
    top_dir = File.join(__dir__, "..", "..", "..")
    command_line_s = [
      Gem.ruby,
      "-I",
      File.join(top_dir, "lib"), 
      File.join(top_dir, "bin", "csv-filter"),
      *cli_option_names,
      filepath,
    ].join(' ')
    Tempfile.create("stdout", mode: File::RDWR) do |stdout|
      Tempfile.create("stderr", mode: File::RDWR) do |stderr|
        status = system(command_line_s, {1 => stdout, 2 => stderr})
        stdout.rewind
        stderr.rewind
        [stdout.read, stderr.read]
      end
    end
  end

  # Return results for CLI-only option (or invalid option).
  def results_for_cli_option(option_name)
    cli_out_s = ''
    cli_err_s = ''
    Dir.mktmpdir do |dirpath|
      sym = option_name.to_sym
      filepath = csv_filepath('', dirpath, sym)
      cli_out_s, cli_err_s = run_csv_filter(filepath, [option_name])
    end
    [cli_out_s, cli_err_s]
  end

  # Get and return the actual output from the API.
  def get_via_api(csv_in_s, **api_options)
    cli_out_s = ''
    CSV.filter(csv_in_s, cli_out_s, **api_options) {|row| }
    cli_out_s
  end

  # Test for invalid option.

  def test_invalid_option
    cli_out_s, cli_err_s = results_for_cli_option('-Z')
    assert_equal("", cli_out_s)
    assert_match(/OptionParser::InvalidOption/, cli_err_s)
  end

  # Test for no options.

  def test_no_options
    csv_in_s = make_csv_s
    cli_out_s = get_via_api(csv_in_s)
    assert_equal(csv_in_s, cli_out_s)
  end

  # Tests for general options.

  def test_option_h
    cli_out_s, cli_err_s = results_for_cli_option('-h')
    assert_equal("Usage: csv-filter [options]\n", cli_out_s.lines.first)
    assert_equal('', cli_err_s)
  end

  def test_option_v
    cli_out_s, cli_err_s = results_for_cli_option('-v')
    assert_match(/\d+\.\d+\.\d+/, cli_out_s)
    assert_equal('', cli_err_s)
  end

end
