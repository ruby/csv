#!/usr/bin/env ruby

require "csv"

require "benchmark/ips"

csv_text = <<EOT
foo,bar,,baz
hoge,,temo,
roo,goo,por,kosh
EOT

convert_nil = ->(s) {s || ""}

Benchmark.ips do |r|
  r.report "not convert" do
    CSV.parse(csv_text)
  end

  r.report "converter" do
    CSV.parse(csv_text, converters: convert_nil)
  end

  r.report "option" do
    CSV.parse(csv_text, nil_value: "")
  end
end
