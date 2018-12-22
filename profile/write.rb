#!/usr/bin/env ruby

require "csv"
require "optparse"

n_columns = 5
n_rows = 100
type = "generate-line"

parser = OptionParser.new
parser.on("--n-columns=N", Integer,
          "The number of columns to be generated",
          "(#{n_columns})") do |n|
  n_columns = n
end
parser.on("--n-rows=N", Integer,
          "The number of rows to be generated",
          "(#{n_rows})") do |n|
  n_rows = n
end
parser.on("--type=TYPE",
          "The type to write",
          "(#{type})") do |t|
  type = t
end
parser.parse!(ARGV)

fields = ["AAAAA"] * n_columns
headers = n_columns.times.collect do |i|
  "header#{i}"
end
row = CSV::Row.new(headers, fields)
raw_row = {}
n_columns.times do |i|
  raw_row[headers[i]] = fields[i]
end

require "profile"

case type
when "generate-line"
  n_rows.times do
    CSV.generate_line(fields)
  end
when "add"
  output = StringIO.new
  csv = CSV.new(output)
  n_rows.times do
    csv << row
  end
else
  raise "unknown type: #{type.inspect}"
end
