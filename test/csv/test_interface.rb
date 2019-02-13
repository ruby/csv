# -*- coding: utf-8 -*-
# frozen_string_literal: false

require_relative "helper"
require "tempfile"

class TestCSVInterface < Test::Unit::TestCase
  extend DifferentOFS

  def setup
    super
    @tempfile = Tempfile.new(%w"temp .csv")
    @tempfile.close
    @path = @tempfile.path

    File.open(@path, "wb") do |file|
      file << "1\t2\t3\r\n"
      file << "4\t5\r\n"
    end

    @expected = [%w{1 2 3}, %w{4 5}]
  end

  def teardown
    @tempfile.close(true)
    super
  end

  ### Test Read and Write Interface ###

  def test_filter
    assert_respond_to(CSV, :filter)

    expected = [[1, 2, 3], [4, 5]]
    CSV.filter( "1;2;3\n4;5\n", (result = String.new),
                in_col_sep: ";", out_col_sep: ",",
                converters: :all ) do |row|
      assert_equal(row, expected.shift)
      row.map! { |n| n * 2 }
      row << "Added\r"
    end
    assert_equal("2,4,6,\"Added\r\"\n8,10,\"Added\r\"\n", result)
  end

  def test_instance
    csv = String.new

    first = nil
    assert_nothing_raised(Exception) do
      first =  CSV.instance(csv, col_sep: ";")
      first << %w{a b c}
    end

    assert_equal("a;b;c\n", csv)

    second = nil
    assert_nothing_raised(Exception) do
      second =  CSV.instance(csv, col_sep: ";")
      second << [1, 2, 3]
    end

    assert_equal(first.object_id, second.object_id)
    assert_equal("a;b;c\n1;2;3\n", csv)

    # shortcuts
    assert_equal(STDOUT, CSV.instance.instance_eval { @io })
    assert_equal(STDOUT, CSV { |new_csv| new_csv.instance_eval { @io } })
  end

  def test_options_are_not_modified
    opt = {}.freeze
    assert_nothing_raised {  CSV.foreach(@path, opt)       }
    assert_nothing_raised {  CSV.open(@path, opt){}        }
    assert_nothing_raised {  CSV.parse("", opt)            }
    assert_nothing_raised {  CSV.parse_line("", opt)       }
    assert_nothing_raised {  CSV.read(@path, opt)          }
    assert_nothing_raised {  CSV.readlines(@path, opt)     }
    assert_nothing_raised {  CSV.table(@path, opt)         }
    assert_nothing_raised {  CSV.generate(opt){}           }
    assert_nothing_raised {  CSV.generate_line([], opt)    }
    assert_nothing_raised {  CSV.filter("", "", opt){}     }
    assert_nothing_raised {  CSV.instance("", opt)         }
  end
end
