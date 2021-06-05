#!/usr/bin/env ruby

$VERBOSE = true

$LOAD_PATH.unshift("test")
$LOAD_PATH.unshift("test/lib")
$LOAD_PATH.unshift("lib")

Dir.glob("test/csv/**/*test_*.rb") do |test_rb|
  # Ensure we only load syntax that we can handle
  next if RUBY_VERSION < "2.7" && test_rb.end_with?("test_patterns.rb")

  require File.expand_path(test_rb)
end
