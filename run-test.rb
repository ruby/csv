#!/usr/bin/env ruby

# Disable Ractor experimental warning
Warning[:experimental] = false

$VERBOSE = true

$LOAD_PATH.unshift("test")
$LOAD_PATH.unshift("test/lib")
$LOAD_PATH.unshift("lib")

require "test/unit"

# Configure test-unit for better stability
Test::Unit::AutoRunner.need_auto_run = false

# Track test execution status
failed_tests = []

Dir.glob("test/csv/**/*test_*.rb") do |test_rb|
  # Ensure we only load syntax that we can handle
  next if RUBY_VERSION < "2.7" && test_rb.end_with?("test_patterns.rb")

  begin
    require File.expand_path(test_rb)
  rescue => e
    puts "Error loading #{test_rb}: #{e.message}"
    puts e.backtrace
    failed_tests << test_rb
  end
end

# Run tests with custom configuration
runner = Test::Unit::AutoRunner.new(true)
runner.process_args([])

# Exit with failure if any tests failed
exit(failed_tests.empty? && runner.run ? 0 : 1)
