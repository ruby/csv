#!/usr/bin/env ruby

require "csv"
require "optparse"

n_rows = 1000
type = "unquoted"

alphas = ["AAAAA"] * 50
hiraganas = ["あああああ"] * 50

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

data = builders[type].call

require "profile"
CSV.parse(data)
