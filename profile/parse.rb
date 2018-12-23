#!/usr/bin/env ruby

require "csv"
require "optparse"

n_columns = 1000
n_rows = 1000
type = "unquoted"

alphas = nil
hiraganas = nil

builders = {
  "unquoted" => lambda {(alphas.join(",") + "\r\n") * n_rows},
  "quoted" => lambda {(alphas.map {|s| %("#{s}")}.join(",") + "\r\n") * n_rows},
  "include-column-separator" =>
    lambda {(alphas.map {|s| %(",#{s}")}.join(",") + "\r\n") * n_rows},
  "include-row-separator" =>
    lambda {(alphas.map {|s| %("#{s}\r\n")}.join(",") + "\r\n") * n_rows},
  "utf-8" => lambda {((hiraganas.join(",") + "\r\n") * n_rows).encode("UTF-8")},
  "windows-31j" =>
    lambda {((hiraganas.join(",") + "\r\n") * n_rows).encode("Windows-31J")},
}

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
parser.on("--type=TYPE", builders.keys,
          "The type for profile",
          "(#{type})") do |t|
  type = t
end
parser.parse!(ARGV)

alphas = ["AAAAA"] * n_columns
hiragans = ["あああああ"] * n_columns

data = builders[type].call

require "profile"
CSV.parse(data)
