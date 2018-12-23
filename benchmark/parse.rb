#!/usr/bin/env ruby

require "csv"
require "optparse"

require "benchmark/ips"

n_columns = 50
n_rows = 1000

parser = OptionParser.new
parser.on("--n-columns=N", Integer,
          "The number of columns to be parsed",
          "(#{n_columns})") do |n|
  n_columns = n
end
parser.on("--n-rows=N", Integer,
          "The number of rows to be parsed",
          "(#{n_rows})") do |n|
  n_rows = n
end
parser.parse!(ARGV)

Benchmark.ips do |x|
  alphas = ["AAAAA"] * n_columns
  unquoted = (alphas.join(",") + "\r\n") * n_rows
  quoted = (alphas.map { |s| %("#{s}") }.join(",") + "\r\n") * n_rows
  inc_col_sep = (alphas.map { |s| %(",#{s}") }.join(",") + "\r\n") * n_rows
  inc_row_sep = (alphas.map { |s| %("#{s}\r\n") }.join(",") + "\r\n") * n_rows

  hiraganas = ["あああああ"] * n_columns
  enc_utf8 = (hiraganas.join(",") + "\r\n") * n_rows
  enc_sjis = enc_utf8.encode("Windows-31J")

  x.report("unquoted") { CSV.parse(unquoted) }
  x.report("quoted") { CSV.parse(quoted) }
  x.report("include col_sep") { CSV.parse(inc_col_sep) }
  x.report("include row_sep") { CSV.parse(inc_row_sep) }
  x.report("encode utf-8") { CSV.parse(enc_utf8) }
  x.report("encode sjis") { CSV.parse(enc_sjis) }
end
