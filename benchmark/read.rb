#!/usr/bin/env ruby

require 'csv'
require 'benchmark/ips'

CSV.open("/tmp/file.csv", "w") do |csv|
  csv << ["player", "gameA", "gameB"]
  1000.times do
    csv << ['"Alice"', "84.0", "79.5"]
    csv << ['"Bob"', "20.0", "56.5"]
  end
end

Benchmark.ips do |x|
  x.report "CSV.foreach" do
    CSV.foreach("/tmp/file.csv") do |row|
    end
  end

  x.report "CSV#shift" do
    CSV.open("/tmp/file.csv") do |csv|
      while _line = csv.shift
      end
    end
  end

  x.report "CSV.read" do
    CSV.read("/tmp/file.csv")
  end

  x.report "CSV.table" do
    CSV.table("/tmp/file.csv")
  end
end
