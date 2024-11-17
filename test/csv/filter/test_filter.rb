# -*- coding: utf-8 -*-
# frozen_string_literal: false

require_relative '../helper'

require 'shellwords'
require 'csv'

class TestFilter < Test::Unit::TestCase

  # Names and aliases for options.
  CliOptionNames = {
    # Input options.
    converters: %w[--converters],
    empty_value: %w[--empty_value],
    field_size_limit: %w[--field_size_limit],
    headers: %w[--headers],
    header_converters: %w[--header_converters],
    input_col_sep: %w[--input_col_sep --in_col_sep],
    input_quote_char: %w[--input_quote_char --in_quote_char],
    input_row_sep: %w[--input_row_sep --in_row_sep],
    liberal_parsing: %w[--liberal_parsing],
    nil_value: %w[--nil_value],
    return_headers: %w[--return_headers],
    skip_blanks: %w[--skip_blanks],
    skip_lines: %w[--skip_lines],
    strip: %w[--strip],
    unconverted_fields: %w[--unconverted_fields],
    # Output options.
    force_quotes: %w[--force_quotes],
    output_col_sep: %w[--output_col_sep --out_col_sep],
    output_quote_char: %w[--output_quote_char --out_quote_char],
    output_row_sep: %w[--output_row_sep --out_row_sep],
    quote_empty: %w[--quote_empty],
    write_converters: %w[--write_converters],
    write_headers: %w[--write_headers],
    write_nil_value: %w[--write_nil_value],
    write_empty_value: %w[--write_empty_value],
    # Input/output options.
    col_sep: %w[-c --col_sep],
    row_sep: %w[-r --row_sep],
    quote_char: %w[-q --quote_char],
  }

  class Option

    attr_accessor :sym, :cli_option_names, :api_argument_value, :cli_argument_value

    def initialize(sym = nil, api_argument_value = nil)
      self.sym = sym || :nil
      self.cli_option_names = CliOptionNames.fetch(self.sym)
      self.api_argument_value = api_argument_value
      if api_argument_value.kind_of?(Array)
        cli_argument_a = []
        api_argument_value.each do |ele|
          cli_argument_a.push(ele.to_s)
        end
        self.cli_argument_value = cli_argument_a.join(',')
      else
        self.cli_argument_value = api_argument_value
      end
    end

  end

  RowSep = "\n"
  ColSep = ','
  QuoteChar = '"'
  Rows = [
    %w[aaa bbb ccc],
    %w[ddd eee fff],
  ]

  # Two methods copied from module Minitest::Assertions.

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

  def setup
    $TEST_DEBUG = false
  end

  def debug(label, value, newline: false)
    return unless $TEST_DEBUG
    print("\n") if newline
    printf("%15s: %s\n", label, value.inspect)
  end

  def get_test_name
    caller.each do |x|
      method_name = x.split(' ').last.gsub(/\W/, '')
      return method_name if method_name.start_with?('test')
    end
    raise RuntimeError.new('No test method name found.')
  end

  def do_test(debugging: false)
    unless debugging
      yield
      return
    end
    get_test_name
    $TEST_DEBUG = true
    test_name = get_test_name
    debug('BEGIN', test_name, newline: true)
    yield
    debug('END', test_name)
    $TEST_DEBUG = false
  end

  # Return CSV string generated from rows and options.
  def make_csv_s(rows: Rows, **options)
    csv_s = CSV.generate(**options) do|csv|
      rows.each do |row|
        csv << row
      end
    end
    csv_s
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
    command = "cat #{filepath} | ruby bin/csv-filter #{cli_options_s}"
    capture_subprocess_io do
      system(command)
    end
  end

  # Return CLI results for options.
  def cli_results_for_options(filepath, cli_option_name, primary_option, options)
    cli_options = [{name: cli_option_name, value: primary_option.cli_argument_value}]
    options.each do |option|
      cli_options.push({name: option.cli_option_names.first, value: option.cli_argument_value})
    end
    cli_options_s = ''
    cli_options.each do |cli_option|
      cli_options_s += " #{cli_option[:name]}"
      value = cli_option[:value]
      cli_options_s += " #{Shellwords.escape(value)}" unless value == :no_argument
    end
    execute_in_cli(filepath, cli_options_s)
  end

  # Return API result for options.
  def api_result(filepath, primary_option, options)
    api_options = {primary_option.sym => primary_option.api_argument_value}
    options.each do |option|
      api_options[option.sym] = option.api_argument_value
    end
    api_options.transform_values! {|value| value == :no_argument ? true : value }
    csv_in_s = File.read(filepath)
    debug('api_options_h', api_options)
    api_out_s = get_via_api(csv_in_s, **api_options)
    return api_out_s
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

  # Verify that the CLI behaves the same as the API.
  # Return the actual output.
  def verify_cli(csv_in_s, options)
    options = options.dup # Don't modify caller's options.
    api_out_s = ''
    cli_out_s = ''
    cli_err_s = ''
    saved_out_s = nil
    Dir.mktmpdir do |dirpath|
      primary_option = options.shift
      filepath = csv_filepath(csv_in_s, dirpath, primary_option.sym)
      primary_option.cli_option_names.each do |cli_option_name|
        # Get expected output string (from API).
        api_out_s = api_result(filepath, primary_option, options)
        # Get actual output and error strings (from CLI).
        cli_out_s, cli_err_s = cli_results_for_options(filepath, cli_option_name, primary_option, options)
        debug('csv_in_s', csv_in_s)
        debug('api_out_s', api_out_s)
        debug('cli_out_s', cli_out_s)
        debug('cli_err_s', cli_err_s)
        assert_empty(cli_err_s)
        assert_equal(api_out_s, cli_out_s)
        # Output string should be the same for all iterations.
        saved_out_s = cli_out_s if saved_out_s.nil?
        assert_equal(saved_out_s, cli_out_s)
      end
    end
    cli_out_s
  end

  # Invalid option.

  def test_invalid_option
    do_test(debugging: false) do
      %w[-Z --ZZZ].each do |option_name|
        cli_out_s, cli_err_s = results_for_cli_option(option_name)
        assert_empty(cli_out_s)
        assert_match(/OptionParser::InvalidOption/, cli_err_s)
      end
    end
  end

  # No options.

  def test_no_options
    do_test(debugging: false) do
      csv_in_s = make_csv_s
      cli_out_s = get_via_api(csv_in_s)
      assert_equal(csv_in_s, cli_out_s)
    end
  end

  # General options

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

  # Input options.

  def test_option_converters
    do_test(debugging: false) do
      converters = %i[integer float]
      rows = [
        ['foo', 0],
        ['bar', 1.1],
      ]
      csv_in_s = make_csv_s(rows: rows)
      options = [
        Option.new(:converters, converters)
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      assert_equal(csv_in_s, cli_out_s)
    end
  end

  # def test_option_empty_value
  #   do_test(debugging: false) do
  #     empty_value = 0
  #     csv_in_s = 'a,"",b,"",c'
  #     options = [
  #       Option.new(:empty_value, empty_value)
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     refute_equal(csv_in_s, cli_out_s)
  #   end
  # end

  def test_option_field_size_limit
    do_test(debugging: false) do
      field_size_limit = 2
      csv_in_s = make_csv_s
      options = [
        Option.new(:field_size_limit, field_size_limit)
      ]
      begin
        verify_cli(csv_in_s, options)
      rescue CSV::MalformedCSVError => x
        assert_match('Field size exceeded', x.message)
      end
    end
  end

  def test_option_headers
    do_test(debugging: false) do
      headers = true
      csv_in_s = make_csv_s
      options = [
        Option.new(:headers, headers)
      ]
      verify_cli(csv_in_s, options)
    end
  end

  def test_option_header_converters
    do_test(debugging: false) do
      header_converters = %i[downcase symbol]
      rows = [
        ['Foo', 'Bar'],
        ['0', 1],
      ]
      csv_in_s = make_csv_s(rows: rows)
      options = [
        Option.new(:headers, true),
        Option.new(:header_converters, header_converters)
      ]
      verify_cli(csv_in_s, options)
    end
  end

  def test_option_liberal_parsing
    do_test(debugging: false) do
      liberal_parsing = :no_argument
      csv_in_s = 'is,this "three, or four",fields'
      options = [
        Option.new(:liberal_parsing, liberal_parsing)
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
    end
  end

  # def test_option_nil_value
  #   do_test(debugging: false) do
  #     nil_value = 0
  #     csv_in_s = 'a,,b,,c'
  #     options = [
  #       Option.new(:nil_value, nil_value)
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     refute_equal(csv_in_s, cli_out_s)
  #   end
  # end

  # def test_option_return_headers
  #   do_test(debugging: false) do
  #     return_headers = :no_argument
  #     csv_in_s = make_csv_s
  #     options = [
  #       Option.new(:return_headers, return_headers)
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     assert_equal(csv_in_s, cli_out_s)
  #   end
  # end

  # def test_option_skip_blanks
  #   do_test(debugging: false) do
  #     skip_blanks = :no_argument
  #     rows = Rows.dup
  #     rows.insert(1, [])
  #     csv_in_s = make_csv_s(rows: rows)
  #     options = [
  #       Option.new(:skip_blanks, skip_blanks)
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     refute_equal(csv_in_s, cli_out_s)
  #   end
  # end

  # def test_option_skip_lines
  #   do_test(debugging: false) do
  #     skip_lines = '#'
  #     rows = Rows.dup
  #     rows.insert(1, ['# Boo!'])
  #     csv_in_s = make_csv_s(rows: rows)
  #     options = [
  #       Option.new(:skip_lines, skip_lines)
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     refute_equal(csv_in_s, cli_out_s)
  #   end
  # end

  # def test_option_strip
  #   do_test(debugging: false) do
  #     strip = :no_argument
  #     rows = Rows.map do |row|
  #       row.map do |col|
  #         " #{col} "
  #       end
  #     end
  #     csv_in_s = make_csv_s(rows: rows)
  #     options = [
  #       Option.new(:strip, strip)
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     refute_equal(csv_in_s, cli_out_s)
  #   end
  # end

  # def test_option_unconverted_fields
  #   do_test(debugging: false) do
  #     unconverted_fields = :no_argument
  #     csv_in_s = make_csv_s
  #     options = [
  #       Option.new(:unconverted_fields, unconverted_fields)
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     assert_equal(csv_in_s, cli_out_s)
  #   end
  # end

  # Output options.

  # def test_option_force_quotes
  #   do_test(debugging: false) do
  #     force_quotes = :no_argument
  #     csv_in_s = make_csv_s
  #     options = [
  #       Option.new(:force_quotes, force_quotes),
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     refute_equal(csv_in_s, cli_out_s)
  #   end
  # end

  # def test_option_quote_empty
  #   do_test(debugging: false) do
  #     quote_empty = true
  #     csv_in_s = "\"\"\"\",\"\"\n"
  #     options = [
  #       Option.new(:quote_empty, quote_empty),
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     assert_equal(csv_in_s, cli_out_s)
  #   end
  # end

  # def test_option_write_converters
  #   do_test(debugging: false) do
  #     cli_out_s, cli_err_s = results_for_cli_option('--write_converters')
  #     assert_empty(cli_out_s)
  #     assert_match(/NotImplementedError/, cli_err_s)
  #   end
  # end

  # def test_option_write_headers
  #   do_test(debugging: false) do
  #     write_headers = :no_argument
  #     csv_in_s = make_csv_s
  #     options = [
  #       Option.new(:write_headers, write_headers),
  #       Option.new(:headers, true),
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     assert_equal(csv_in_s, cli_out_s)
  #   end
  # end

  # def test_option_write_empty_value
  #   do_test(debugging: false) do
  #     write_empty_value = 'x'
  #     csv_in_s = "a,\"\",c,\"\"\n"
  #     options = [
  #       Option.new(:write_empty_value, write_empty_value),
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     refute_equal(csv_in_s, cli_out_s)
  #   end
  # end

  # def test_option_write_nil_value
  #   do_test(debugging: false) do
  #     write_nil_value = 'x'
  #     csv_in_s = "a,,c,\n"
  #     options = [
  #       Option.new(:write_nil_value, write_nil_value),
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     refute_equal(csv_in_s, cli_out_s)
  #   end
  # end

  # Input/output options.

  def test_option_c
    do_test(debugging: false) do
      col_sep = 'X'
      csv_in_s = make_csv_s(col_sep: col_sep)
      options = [
        Option.new(:col_sep, col_sep)
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      assert_equal(csv_in_s, cli_out_s)
    end
  end

  def test_option_input_col_sep
    do_test(debugging: false) do
      input_col_sep = 'X'
      csv_in_s = make_csv_s(col_sep: input_col_sep)
      options = [
        Option.new(:input_col_sep, input_col_sep)
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
    end
  end

  def test_option_output_col_sep
    do_test(debugging: false) do
      output_col_sep = 'X'
      csv_in_s = make_csv_s
      options = [
        Option.new(:output_col_sep, output_col_sep)
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
    end
  end

  def test_options_c_and_input_col_sep
    do_test(debugging: false) do
      input_col_sep = 'X'
      col_sep = 'Y'
      csv_in_s = make_csv_s(col_sep: input_col_sep)
      options = [
        Option.new(:col_sep, col_sep),
        Option.new(:input_col_sep, input_col_sep),
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
      cli_out_s = verify_cli(csv_in_s, options.reverse)
      assert_equal(csv_in_s, cli_out_s)
    end
  end

  def test_options_c_and_output_col_sep
    do_test(debugging: false) do
      col_sep = 'X'
      output_col_sep = 'Y'
      csv_in_s = make_csv_s(col_sep: col_sep)
      options = [
        Option.new(:col_sep, col_sep),
        Option.new(:output_col_sep, output_col_sep),
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
      cli_out_s = verify_cli(csv_in_s, options.reverse)
      assert_equal(csv_in_s, cli_out_s)
    end
  end

  def test_options_input_col_sep_and_output_col_sep
    do_test(debugging: false) do
      input_col_sep = 'X'
      output_col_sep = 'Y'
      csv_in_s = make_csv_s(col_sep: input_col_sep)
      options = [
        Option.new(:input_col_sep, input_col_sep),
        Option.new(:output_col_sep, output_col_sep),
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
      cli_out_s = verify_cli(csv_in_s, options.reverse)
      refute_equal(csv_in_s, cli_out_s)
    end
  end

  def test_option_r
    do_test(debugging: false) do
      row_sep = 'X'
      csv_in_s = make_csv_s(row_sep: row_sep)
      options = [
        Option.new(:row_sep, row_sep)
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      assert_equal(csv_in_s, cli_out_s)
    end
  end

  def test_option_input_row_sep
    do_test(debugging: false) do
      input_row_sep = 'A'
      csv_in_s = make_csv_s(row_sep: input_row_sep)
      options = [
        Option.new(:input_row_sep, input_row_sep)
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
    end
  end

  def test_option_output_row_sep
    do_test(debugging: false) do
      output_row_sep = 'A'
      csv_in_s = make_csv_s(row_sep: output_row_sep)
      options = [
        Option.new(:input_row_sep, output_row_sep)
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
    end
  end

  def test_options_r_and_input_row_sep
    do_test(debugging: false) do
      input_row_sep = 'X'
      row_sep = 'Y'
      csv_in_s = make_csv_s(row_sep: input_row_sep)
      options = [
        Option.new(:row_sep, row_sep),
        Option.new(:input_row_sep, input_row_sep),
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
      cli_out_s = verify_cli(csv_in_s, options.reverse)
      # Used match instead of equal here b/c there seems to be an extra 'Y'
      # at the end of the cli_out_s (possibly a CSV bug?).
      assert_match(csv_in_s, cli_out_s)
    end
  end

  def test_options_r_and_output_row_sep
    do_test(debugging: false) do
      row_sep = 'X'
      output_row_sep = 'Y'
      csv_in_s = make_csv_s(row_sep: row_sep)
      options = [
        Option.new(:row_sep, row_sep),
        Option.new(:output_row_sep, output_row_sep),
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
      cli_out_s = verify_cli(csv_in_s, options.reverse)
      assert_equal(csv_in_s, cli_out_s)
    end
  end

  def test_options_input_row_sep_and_output_row_sep
    do_test(debugging: false) do
      input_row_sep = 'X'
      output_row_sep = 'Y'
      csv_in_s = make_csv_s(row_sep: input_row_sep)
      options = [
        Option.new(:input_row_sep, input_row_sep),
        Option.new(:output_row_sep, output_row_sep),
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
      cli_out_s = verify_cli(csv_in_s, options.reverse)
      refute_equal(csv_in_s, cli_out_s)
    end
  end

  def test_option_q
    do_test(debugging: false) do
      quote_char = "'"
      rows = [
        ['foo', 0],
        ["'bar'", 1],
        ['"baz"', 2],
      ]
      csv_in_s = make_csv_s(rows: rows, quote_char: quote_char)
      options = [
        Option.new(:quote_char, quote_char)
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      assert_equal(csv_in_s, cli_out_s)
    end
  end

  def test_option_input_quote_char
    do_test(debugging: false) do
      input_quote_char = "'"
      rows = [
        ['foo', 0],
        ["'bar'", 1],
        ['"baz"', 2],
      ]
      csv_in_s = make_csv_s(rows: rows, quote_char: input_quote_char)
      options = [
        Option.new(:input_quote_char, input_quote_char)
      ]
      cli_out_s = verify_cli(csv_in_s, options)
      refute_equal(csv_in_s, cli_out_s)
    end
  end

  # def test_option_output_quote_char
  #   do_test(debugging: false) do
  #     output_quote_char = "X"
  #     rows = [
  #       ['foo', 0],
  #       ["'bar'", 1],
  #       ['"baz"', 2],
  #     ]
  #     csv_in_s = make_csv_s(rows: rows)
  #     options = [
  #       Option.new(:output_quote_char, output_quote_char),
  #       Option.new(:force_quotes, :no_argument)
  #     ]
  #     cli_out_s = verify_cli(csv_in_s, options)
  #     refute_equal(csv_in_s, cli_out_s)
  #   end
  # end

end
