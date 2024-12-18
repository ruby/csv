# frozen_string_literal: false

require_relative "../helper"

class TestFilter < Test::Unit::TestCase

  def setup
    @input = [
      %w[aaa bbb ccc].join(","),
      %w[ddd eee fff].join(","),
      "" # Force trailing newline.
    ].join("\n")
  end

  # Return filepath of file containing CSV data.
  def csv_filepath(input, dirpath, option)
    filename = "#{option}.csv"
    filepath = File.join(dirpath, filename)
    File.write(filepath, input)
    filepath
  end

  # Return stdout and stderr from CLI execution.
  def run_csv_filter(filepath, *cli_option_names)
    top_dir = File.join(__dir__, "..", "..", "..")
    command_line = [
      Gem.ruby,
      "-I",
      File.join(top_dir, "lib"), 
      File.join(top_dir, "bin", "csv-filter"),
      *cli_option_names,
      filepath,
    ].join(" ")
    Tempfile.create("stdout", mode: File::RDWR) do |stdout|
      Tempfile.create("stderr", mode: File::RDWR) do |stderr|
        status = system(command_line, {1 => stdout, 2 => stderr})
        stdout.rewind
        stderr.rewind
        [stdout.read, stderr.read]
      end
    end
  end

  # Return results for CLI-only option (or invalid option).
  def results_for_cli_option(option_name)
    output = ""
    error = ""
    Dir.mktmpdir do |dirpath|
      sym = option_name.to_sym
      filepath = csv_filepath("", dirpath, sym)
      output, error = run_csv_filter(filepath, [option_name])
    end
    [output, error]
  end

  # Get and return the actual output from the API.
  def api_output(input, **api_options)
    output = ""
    CSV.filter(input, output, **api_options) {|row| }
    output
  end

  # Test for invalid option.

  def test_invalid_option
    output, error = results_for_cli_option("-Z")
    assert_equal("", output)
    assert_match(/OptionParser::InvalidOption/, error)
  end

  # Test for no options.

  def test_no_options
    output = api_output(@input)
    assert_equal(@input, output)
  end

  # Tests for general options.

  def test_option_h
    output, error = results_for_cli_option("-h")
    assert_equal("Usage: csv-filter [options]\n", output.lines.first)
    assert_equal("", error)
  end

  def test_option_v
    output, error = results_for_cli_option("-v")
    assert_match(/\d+\.\d+\.\d+/, output)
    assert_equal("", error)
  end

end
