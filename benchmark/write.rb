#!/usr/bin/env ruby

require "csv"
require "optparse"

require "benchmark/ips"

n_columns = 5
n_rows = 100

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
parser.parse!(ARGV)

Benchmark.ips do |job|
  fields = ["AAAAA"] * n_columns
  headers = n_columns.times.collect do |i|
    "header#{i}"
  end
  row = CSV::Row.new(headers, fields)
  raw_row = {}
  n_columns.times do |i|
    raw_row[headers[i]] = fields[i]
  end

  job.report("generate_line: fields") do
    n_rows.times do
      CSV.generate_line(fields)
    end
  end

  job.report("generate_line: Row") do
    n_rows.times do
      CSV.generate_line(row)
    end
  end

  job.report("generate_line: Hash") do
    n_rows.times do
      CSV.generate_line(raw_row, headers: headers)
    end
  end

  job.report("<< fields") do
    output = StringIO.new
    csv = CSV.new(output)
    n_rows.times do
      csv << fields
    end
  end

  job.report("<< Row") do
    output = StringIO.new
    csv = CSV.new(output)
    n_rows.times do
      csv << row
    end
  end

  job.report("<< Hash") do
    output = StringIO.new
    csv = CSV.new(output, headers: headers)
    n_rows.times do
      csv << raw_row
    end
  end

  job.report("<< fields: write headers") do
    output = StringIO.new
    csv = CSV.new(output, headers: headers, write_headers: true)
    n_rows.times do
      csv << fields
    end
  end

  job.report("<< Row: write headers") do
    output = StringIO.new
    csv = CSV.new(output, headers: headers, write_headers: true)
    n_rows.times do
      csv << row
    end
  end

  job.report("<< Hash: write headers") do
    output = StringIO.new
    csv = CSV.new(output, headers: headers, write_headers: true)
    n_rows.times do
      csv << raw_row
    end
  end
end
