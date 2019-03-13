# frozen_string_literal: false

require_relative "../helper"

class TestCSVInterfaceDelegation < Test::Unit::TestCase
  def test_stringio_missing_methods_delegation
    csv = CSV.new("h1,h2")

    assert_raise(NotImplementedError) { csv.flock(0) }
    assert_raise(NotImplementedError) { csv.ioctl(0) }
    assert_raise(NotImplementedError) { csv.stat }
    assert_raise(NotImplementedError) { csv.to_i }

    assert_equal(false, csv.binmode?)
    assert_equal(nil, csv.path)
    assert_instance_of(StringIO, csv.to_io)
  end
end
