# frozen_string_literal: true

require_relative "lib/csv"

Gem::Specification.new do |spec|
  spec.name          = "csv"
  spec.version       = CSV::VERSION
  spec.date          = "2017-12-14"
  spec.authors       = ["James Edward Gray II"]
  spec.email         = [nil]

  spec.summary       = "CSV Reading and Writing"
  spec.description   = "The CSV library provides a complete interface to CSV files and data. It offers tools to enable you to read and write to and from Strings or IO objects, as needed."
  spec.homepage      = "https://github.com/ruby/csv"
  spec.license       = "BSD-2-Clause"

  spec.files         = ["lib/csv.rb", "lib/core_ext/array.rb", "lib/core_ext/string.rb"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.4.0"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 12"
end
