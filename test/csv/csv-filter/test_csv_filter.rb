# -*- coding: utf-8 -*-
# frozen_string_literal: false

require_relative '../helper'

require 'csv'

class TestFilter < Test::Unit::TestCase

  # Some rows data (useful as default).
  Rows = [
    %w[aaa bbb ccc],
    %w[ddd eee fff],
  ]

  def setup
    # In case the previous test left this as true.
    $TEST_DEBUG = false
  end

  # Print debugging information if indicated.
  def debug(label, value, newline: false)
    return unless $TEST_DEBUG
    print("\n") if newline
    printf("%15s: %s\n", label, value.inspect)
  end

  # Return the test name (retrieved from the call stack).
  def get_test_name
    caller.each do |x|
      method_name = x.split(' ').last.gsub(/\W/, '')
      return method_name if method_name.start_with?('test')
    end
    raise RuntimeError.new('No test method name found.')
  end

  # Perform the testing defined in the caller's block.
  def do_test(debugging: false)
    # Just the caller's block, unless debugging.
    unless debugging
      yield
      return
    end
    # Wrap the caller's block with debugging information.
    $TEST_DEBUG = true
    test_name = get_test_name
    debug('BEGIN', test_name, newline: true)
    yield
    debug('END', test_name)
    $TEST_DEBUG = false
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
  def execute_in_cli(filepath, cli_options_s = '')
    debug('cli_options_s', cli_options_s)
    top_dir = File.join(__dir__, "..", "..", "..")
    command_line = [
      Gem.ruby,
      "-I",
      File.join(top_dir, "lib"), 
      File.join(top_dir, "bin", "csv-filter"),
      *options,
      filepath,
    ]
    Tempfile.create("stdout", mode: "rw") do |stdout|
      Tempfile.create("stderr", mode: "rw") do |stderr|
        status = system(*command_line, {1 => stdout, 2 => stderr})
        stdout.rewind
        stderr.rewind
        [status, stdout.read, stderr.read]
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
      cli_out_s, cli_err_s = execute_in_cli(filepath, option_name)
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
    do_test(debugging: false) do
      %w[-Z --ZZZ].each do |option_name|
        cli_out_s, cli_err_s = results_for_cli_option(option_name)
        assert_equal("", cli_out_s)
        assert_match(/OptionParser::InvalidOption/, cli_err_s)
      end
    end
  end

  # Test for no options.

  def test_no_options
    do_test(debugging: false) do
      csv_in_s = make_csv_s
      cli_out_s = get_via_api(csv_in_s)
      assert_equal(csv_in_s, cli_out_s)
    end
  end

  # Tests for general options.

  def test_option_h
    do_test(debugging: false) do
      %w[-h --help].each do |option_name|
        cli_out_s, cli_err_s = results_for_cli_option(option_name)
        assert_match(/Usage/, cli_out_s)
        assert_empty(cli_err_s)
      end
    end
  end

  def test_option_v
    do_test(debugging: false) do
      %w[-v --version].each do |option_name|
        cli_out_s, cli_err_s = results_for_cli_option(option_name)
        assert_match(/\d+\.\d+\.\d+/, cli_out_s)
        assert_empty(cli_err_s)
      end
    end
  end

  # Two methods copied from module Minitest::Assertions.
  # because we need access to the subprocess io.

  def _synchronize # :nodoc:
    yield
  end

  def capture_subprocess_io
    _synchronize do
      begin
        require "tempfile"

        captured_stdout, captured_stderr = Tempfile.new("out"), Tempfile.new("err")

        orig_stdout, orig_stderr = $stdout.dup, $stderr.dup
        $stdout.reopen captured_stdout
        $stderr.reopen captured_stderr

        yield

        $stdout.rewind
        $stderr.rewind

        return captured_stdout.read, captured_stderr.read
      ensure
        $stdout.reopen orig_stdout
        $stderr.reopen orig_stderr

        orig_stdout.close
        orig_stderr.close
        captured_stdout.close!
        captured_stderr.close!
      end
    end
  end

end
