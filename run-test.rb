#!/usr/bin/env ruby

$VERBOSE = true

$LOAD_PATH.unshift("test")
$LOAD_PATH.unshift("test/lib")
$LOAD_PATH.unshift("lib")

Dir.glob("test/csv/**/*test_*.rb") do |test_rb|
  require File.expand_path(test_rb)
end
