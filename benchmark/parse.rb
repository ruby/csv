#!/usr/bin/env ruby

require "csv"
require "optparse"

require "benchmark/ips"

n_rows = 1000

parser = OptionParser.new
parser.on("--n-rows=N", Integer,
          "The number of rows to be parsed",
          "(#{n_rows})") do |n|
  n_rows = n
end
parser.parse!(ARGV)

Benchmark.ips do |x|
  alphas = ["AAAAA"] * 50
  unquoted = (alphas.join(",") + "\r\n") * n_rows
  quoted = (alphas.map { |s| %("#{s}") }.join(",") + "\r\n") * n_rows
  inc_col_sep = (alphas.map { |s| %(",#{s}") }.join(",") + "\r\n") * n_rows
  inc_row_sep = (alphas.map { |s| %("#{s}\r\n") }.join(",") + "\r\n") * n_rows

  hiraganas = ["あああああ"] * 50
  enc_utf8 = (hiraganas.join(",") + "\r\n") * n_rows
  enc_sjis = enc_utf8.encode("Windows-31J")

  options = {
    need_line: false
  }

  x.report("unquoted (optimized)") { CSV.parse(unquoted, **options) }
  x.report("quoted (optimized)") { CSV.parse(quoted, **options) }
  x.report("include col_sep (optimized)") { CSV.parse(inc_col_sep, **options) }
  x.report("include row_sep (optimized)") { CSV.parse(inc_row_sep, **options) }
  x.report("encode utf-8 (optimized)") { CSV.parse(enc_utf8, **options) }
  x.report("encode sjis (optimized)") { CSV.parse(enc_sjis, **options) }

  x.report("unquoted") { CSV.parse(unquoted) }
  x.report("quoted") { CSV.parse(quoted) }
  x.report("include col_sep") { CSV.parse(inc_col_sep) }
  x.report("include row_sep") { CSV.parse(inc_row_sep) }
  x.report("encode utf-8") { CSV.parse(enc_utf8) }
  x.report("encode sjis") { CSV.parse(enc_sjis) }
end
