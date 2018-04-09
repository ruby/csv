#!/usr/bin/env ruby

require "csv"

require "benchmark/ips"

csv_text = <<CSV
foo,bar,,baz
hoge,,temo,
roo,goo,por,kosh
CSV

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

  r.compare!
end
