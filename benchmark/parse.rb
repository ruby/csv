# benchmark script for CSV.parse
# Usage: `ruby $0 [rows count(default: 1000)]`
require 'csv'
require 'benchmark/ips'

Benchmark.ips do |x|
  rows = ARGV.fetch(0, "1000").to_i

  alphas = ['AAAAA'] * 50
  unquoted = (alphas.join(',') + "\r\n") * rows
  quoted = (alphas.map { |s| %("#{s}") }.join(',') + "\r\n") * rows
  inc_col_sep = (alphas.map { |s| %(",#{s}") }.join(',') + "\r\n") * rows
  inc_row_sep = (alphas.map { |s| %("#{s}\r\n") }.join(',') + "\r\n") * rows

  hiraganas = ['あああああ'] * 50
  enc_utf8 = (hiraganas.join(',') + "\r\n") * rows
  enc_sjis = enc_utf8.encode('Windows-31J')

  x.report("unquoted") { CSV.parse(unquoted) }
  x.report("quoted") { CSV.parse(quoted) }
  x.report("include col_sep") { CSV.parse(inc_col_sep) }
  x.report("include row_sep") { CSV.parse(inc_row_sep) }
  x.report("encode utf-8") { CSV.parse(enc_utf8) }
  x.report("encode sjis") { CSV.parse(enc_sjis) }
end
