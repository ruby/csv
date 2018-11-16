# CSV

[![Build Status](https://travis-ci.org/ruby/csv.svg?branch=master)](https://travis-ci.org/ruby/csv)
[![Test Coverage](https://api.codeclimate.com/v1/badges/321fa39e510a0abd0369/test_coverage)](https://codeclimate.com/github/ruby/csv/test_coverage)

This library provides a complete interface to CSV files and data. It offers tools to enable you to read and write to and from Strings or IO objects, as needed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'csv'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install csv

## Usage

```ruby
require "csv"

CSV.foreach("path/to/file.csv") do |row|
  # use row here...
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/csv.

### NOTE: About RuboCop

We don't use RuboCop because we can manage our coding style by ourselves. We want to accept small fluctuations in our coding style because we use Ruby.
Please do not submit issues and PRs that aim to introduce RuboCop in this repository.

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).

See LICENSE.txt for details.
